class ImagesController < ApplicationController
  include Ogp::ImageGenerator

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [ :ogp ]
  before_action :set_cors_headers, only: [ :ogp ]

  def ogp
    begin
      # テスト用のダミー画像を返す
      dummy_image = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x00\x00\x02\x00\x01\xe5\x27\xde\xfc\x00\x00\x00\x00IEND\xaeB`\x82"
      send_data dummy_image, type: "image/png", disposition: "inline"
    rescue StandardError => e
      Rails.logger.error "OGP画像生成エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      head :internal_server_error
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

  def generate_ogp_image(title:, emotion:, song_name:, artist_name:)
    # 既存の画像生成ロジック
  end
end
