class ImagesController < ApplicationController
  include Ogp::ImageGenerator

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [ :ogp ]
  before_action :set_cors_headers, only: [ :ogp ]

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
      validate_base_image
      validate_album_image_url(album_image_url) if album_image_url.present?

      image_data = Generator.build(text, album_image_url)

      if image_data.nil?
        Rails.logger.error "Generated image data is nil"
        render plain: "Error: Failed to generate image", status: :internal_server_error
        return
      end

      send_data image_data, type: "image/png", disposition: "inline"
    rescue => e
      handle_ogp_error(e)
    end
  end

  private

  def validate_base_image
    base_image_path = Rails.root.join("app/assets/images/ogp.png")
    unless File.exist?(base_image_path)
      Rails.logger.error "Base image not found at: #{base_image_path}"
      raise "Base image not found"
    end
  end

  def validate_album_image_url(url)
    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      raise "Invalid album image URL format"
    end
  end

  def handle_ogp_error(error)
    Rails.logger.error "Error in OGP generation: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    render plain: "Error: #{error.message}", status: :internal_server_error
  end

  def set_cors_headers
    allowed_origins = [ "https://ogp.buta3.net", "https://cards-dev.twitter.com", "https://www.facebook.com" ]
    if allowed_origins.include?(request.headers["Origin"])
      response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
    else
      response.headers["Access-Control-Allow-Origin"] = "*"
    end
    response.headers["Access-Control-Allow-Methods"] = "GET, HEAD, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
    response.headers["Access-Control-Max-Age"] = "86400"  # 24時間
    response.headers["Cache-Control"] = "public, max-age=31536000"
    response.headers["Expires"] = 1.year.from_now.httpdate
  end

  def ogp_params
    params.permit(:text, :album_image)
  end
end
