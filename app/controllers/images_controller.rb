class ImagesController < ApplicationController
  include Ogp::ImageGenerator

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [ :ogp ]
  before_action :set_cors_headers, only: [ :ogp ]

  def ogp
    begin
      # パラメータの取得と整形
      text_parts = params[:text].to_s.split(" - ")
      song_name = text_parts[0]
      artist_name = text_parts[1]

      # OGP画像生成
      image = generate_ogp_image(
        album_image: params[:album_image],
        song_name: song_name,
        artist_name: artist_name
      )

      # レスポンスの設定
      response.headers["Content-Type"] = "image/png"
      send_data image.to_blob, type: "image/png", disposition: "inline"
    rescue StandardError => e
      Rails.logger.error "OGP画像生成エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # デフォルトのOGP画像を返す
      default_ogp_path = Rails.root.join("app/assets/images/ogp.png")
      send_file default_ogp_path, type: "image/png", disposition: "inline"
    end
  end

  private

  def generate_ogp_image(album_image:, song_name:, artist_name:)
    # ベース画像の読み込み
    base_image_path = Rails.root.join("app/assets/images/ogp.png")
    image = MiniMagick::Image.open(base_image_path)

    # フォントの設定
    font_path = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf").to_s

    # テキストとアルバムアートを中央揃えで配置
    image.combine_options do |c|
      c.font font_path
      c.fill "#333333"
      c.gravity "North"  # 上端を基準に

      # 曲名（上部）
      c.pointsize 48
      c.draw "text 0,40 '#{song_name}'"  # 上部の余白を増やす

      # アーティスト名
      c.pointsize 36
      c.draw "text 0,110 '#{artist_name}'"  # 曲名との間隔を広げる
    end

    # アルバムアート
    if album_image.present?
      begin
        album_art = MiniMagick::Image.open(album_image)
        album_art.resize "350x350"  # サイズを少し小さく

        image = image.composite(album_art) do |c|
          c.compose "Over"
          c.gravity "Center"
          c.geometry "+0+30"  # 中央よりやや下に
        end
      rescue => e
        Rails.logger.error "アルバム画像の処理に失敗: #{e.message}"
      end
    end

    # MY-SONG-JOURNALとURL
    image.combine_options do |c|
      c.font font_path
      c.fill "#333333"
      c.gravity "South"  # 下端を基準に

      # MY-SONG-JOURNAL
      c.pointsize 36
      c.draw "text 0,-100 'MY-SONG-JOURNAL'"  # 下部の余白を増やす

      # URL
      c.pointsize 24
      c.draw "text 0,-50 'og.nullnull.dev'"  # MY-SONG-JOURNALとの間隔を広げる
    end

    # デバッグ用：生成された画像を一時ファイルに保存
    temp_path = "/tmp/debug_ogp_#{Time.now.to_i}.png"
    image.write(temp_path)
    Rails.logger.info "Debug: OGP image saved to #{temp_path}"

    image
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
end
