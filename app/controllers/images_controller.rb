class ImagesController < ApplicationController
  include Ogp::ImageGenerator

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [ :ogp ]
  before_action :set_cors_headers, only: [ :ogp ]

  def ogp
    begin
      # textパラメータからsong_nameとartist_nameを抽出
      text_parts = params[:text].split(" - ")
      song_name = text_parts[0]
      artist_name = text_parts[1]

      # OGP画像生成処理
      image = generate_ogp_image(
        album_image: params[:album_image],  # 正しいパラメータ名に修正
        title: params[:text],
        emotion: "♪",
        song_name: song_name,
        artist_name: artist_name
      )

      response.headers["Content-Type"] = "image/png"
      send_data image.to_blob, type: "image/png", disposition: "inline"
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
    allowed_origins = [
      "https://ogp.buta3.net",
      "https://cards-dev.twitter.com",
      "https://twitter.com",
      "https://x.com"
    ]

    if allowed_origins.include?(request.headers["Origin"])
      response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
    end

    response.headers["Access-Control-Allow-Methods"] = "GET, HEAD, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
    response.headers["Cache-Control"] = "public, max-age=31536000"
    response.headers["Expires"] = 1.year.from_now.httpdate
  end

  def ogp_params
    params.permit(:text, :album_image)
  end

  def generate_ogp_image(title:, emotion:, song_name:, artist_name:, album_image:)
    # 画像の基本設定
    image = MiniMagick::Image.new(1200, 630, "white")

    # アルバムアート画像を読み込んで配置
    album_art = MiniMagick::Image.open(album_image)
    album_art.resize("400x400")
    image.composite(album_art) do |c|
      c.compose "Over"
      c.geometry "+50+115"  # 左側に配置
    end

    # テキストを描画
    draw = MiniMagick::Draw.new
    draw.font("Arial")

    # タイトル
    draw.pointsize(48)
    draw.text(480, 200, title)

    # 感情
    draw.pointsize(36)
    draw.text(480, 300, "Emotion: #{emotion}")

    # 曲名とアーティスト
    draw.pointsize(32)
    draw.text(480, 400, "#{song_name} by #{artist_name}")

    # 描画を実行
    draw.draw(image)

    image
  end
end
