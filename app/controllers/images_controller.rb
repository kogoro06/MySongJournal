class ImagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [:ogp]
  before_action :set_cors_headers, only: [:ogp]

  def ogp
    text = params[:text]
    album_image_url = params[:album_image]

    Rails.logger.warn "=== OGP Controller Debug Info ==="
    Rails.logger.warn "Received text parameter: #{text.inspect}"
    Rails.logger.warn "Received album_image parameter: #{album_image_url.inspect}"
    Rails.logger.warn "Request URL: #{request.url}"
    Rails.logger.warn "Request parameters: #{params.inspect}"
    Rails.logger.warn "User Agent: #{request.user_agent}"
    Rails.logger.warn "Referer: #{request.referer}"
    Rails.logger.warn "Accept header: #{request.headers['Accept']}"

    begin
      # ベース画像の存在確認
      base_image_path = Rails.root.join("app/assets/images/ogp.png")
      unless File.exist?(base_image_path)
        Rails.logger.error "Base image not found at: #{base_image_path}"
        render plain: "Error: Base image not found", status: :not_found
        return
      end

      # アルバム画像のURLをチェック
      if album_image_url.present?
        begin
          uri = URI.parse(album_image_url)
          Rails.logger.warn "Parsed URI scheme: #{uri.scheme}"
          Rails.logger.warn "Parsed URI host: #{uri.host}"
          Rails.logger.warn "Parsed URI path: #{uri.path}"

          unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            Rails.logger.error "Invalid album image URL format: #{album_image_url}"
            render plain: "Error: Invalid album image URL", status: :bad_request
            return
          end

          # ヘッドリクエストでURLの有効性を確認
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.head(uri.path)
          end
          Rails.logger.warn "HEAD request response code: #{response.code}"
          Rails.logger.warn "HEAD request content type: #{response['content-type']}"

        rescue URI::InvalidURIError => e
          Rails.logger.error "Failed to parse album image URL: #{e.message}"
          render plain: "Error: Invalid album image URL", status: :bad_request
          return
        rescue => e
          Rails.logger.error "Failed to check album image URL: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end

      # 画像生成
      image_data = OgpCreator.build(text, album_image_url)

      if image_data.nil?
        Rails.logger.error "Generated image data is nil"
        render plain: "Error: Failed to generate image", status: :internal_server_error
        return
      end

      Rails.logger.warn "OGP image generated successfully"
      send_data image_data, type: "image/png", disposition: "inline"
    rescue => e
      Rails.logger.error "Error in OGP generation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render plain: "Error: #{e.message}", status: :internal_server_error
    end
  end

  private

  def set_cors_headers
    allowed_origins = ['https://ogp.buta3.net', 'https://cards-dev.twitter.com', 'https://www.facebook.com']
    if allowed_origins.include?(request.headers['Origin'])
      response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
    else
      response.headers['Access-Control-Allow-Origin'] = '*'
    end
    response.headers['Access-Control-Allow-Methods'] = 'GET, HEAD, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept'
    response.headers['Access-Control-Max-Age'] = '86400'  # 24時間
  end

  def ogp_params
    params.permit(:text, :album_image)
  end
end