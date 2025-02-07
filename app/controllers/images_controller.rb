class ImagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def ogp
    text = params[:text]
    album_image_url = params[:album_image]

    Rails.logger.info "=== OGP Controller Debug Info ==="
    Rails.logger.info "Received text parameter: #{text.inspect}"
    Rails.logger.info "Received album_image parameter: #{album_image_url.inspect}"
    Rails.logger.info "Request URL: #{request.url}"
    Rails.logger.info "Request parameters: #{params.inspect}"
    Rails.logger.info "User Agent: #{request.user_agent}"
    Rails.logger.info "Referer: #{request.referer}"

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
          Rails.logger.info "Parsed URI scheme: #{uri.scheme}"
          Rails.logger.info "Parsed URI host: #{uri.host}"
          Rails.logger.info "Parsed URI path: #{uri.path}"

          unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            Rails.logger.error "Invalid album image URL format: #{album_image_url}"
            render plain: "Error: Invalid album image URL", status: :bad_request
            return
          end

          # ヘッドリクエストでURLの有効性を確認
          response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.head(uri.path)
          end
          Rails.logger.info "HEAD request response code: #{response.code}"
          Rails.logger.info "HEAD request content type: #{response['content-type']}"

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

      Rails.logger.info "OGP image generated successfully"
      
      # Accept-Headerに関係なく常にPNGとして返す
      response.headers['Content-Type'] = 'image/png'
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Cache-Control'] = 'public, max-age=31536000'
      
      # バイナリデータとして送信
      send_data image_data,
        type: 'image/png',
        disposition: 'inline',
        status: :ok
    rescue => e
      Rails.logger.error "Error in OGP generation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render plain: "Error: #{e.message}", status: :internal_server_error
    end
  end

  private

  def ogp_params
    params.permit(:text, :album_image)
  end
end