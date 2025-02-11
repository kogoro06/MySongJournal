class ImagesController < ApplicationController
  include Ogp::ImageGenerator

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [ :ogp ]
  before_action :set_cors_headers, only: [ :ogp ]

  def ogp
    Rails.logger.info "OGP Request Parameters: #{params.inspect}"
    Rails.logger.info "User Agent: #{request.user_agent}"

    begin
      # パラメータの取得と整形
      text = params[:text].to_s
      parts = text.split(" - ").map(&:strip)
      
      # 曲名とアーティスト名を正しく抽出
      song_name = parts[0]
      artist_name = if parts.size > 2
        # "曲名 - From xxx - アーティスト名" のパターン
        parts.last
      else
        # "曲名 - アーティスト名" のパターン
        parts[1]
      end

      Rails.logger.info "Parsed song name: #{song_name.inspect}"
      Rails.logger.info "Parsed artist name: #{artist_name.inspect}"

      cache_key = "ogp/#{Digest::MD5.hexdigest([song_name, artist_name, params[:album_image]].join('_'))}"
      Rails.logger.info "Cache key: #{cache_key}"
      
      image_data = Rails.cache.fetch(cache_key, expires_in: 1.week) do
        Rails.logger.info "Cache miss - Generating new OGP image"
        Rails.logger.info "Generating OGP image for song: #{song_name}, artist: #{artist_name}"

        # 画像生成とバイナリデータへの変換を一度に行う
        image = generate_ogp_image(
          album_image: params[:album_image],
          song_name: song_name,
          artist_name: artist_name
        )
        
        Rails.logger.info "Image generated successfully, converting to blob"
        blob = image.to_blob
        image.destroy!
        blob
      end

      Rails.logger.info "Image data size: #{image_data.bytesize} bytes"

      # レスポンスヘッダーの設定
      response.headers["Content-Type"] = "image/png"
      response.headers["Cache-Control"] = "public, max-age=31536000"
      response.headers["ETag"] = %("#{Digest::MD5.hexdigest(image_data)}")

      # 条件付きGETのチェック
      if stale?(etag: response.headers["ETag"])
        Rails.logger.info "Sending image data..."
        send_data image_data, type: "image/png", disposition: "inline"
      else
        Rails.logger.info "304 Not Modified response sent"
      end
    rescue StandardError => e
      Rails.logger.error "OGP画像生成エラー: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      Rails.logger.error "Parameters: #{params.inspect}"
      
      # デフォルトのOGP画像を返す
      default_ogp_path = Rails.root.join("app/assets/images/ogp.png")
      Rails.logger.info "Sending default OGP image: #{default_ogp_path}"
      send_file default_ogp_path, type: "image/png", disposition: "inline"
    end
  end

  private

  def generate_ogp_image(album_image:, song_name:, artist_name:)
    Rails.logger.info "Starting OGP image generation"
    start_time = Time.current

    base_image_path = Rails.root.join("app/assets/images/ogp.png")
    image = MiniMagick::Image.open(base_image_path)
    font_path = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf").to_s

    # テキストを追加
    image.combine_options do |c|
      c.font font_path
      c.fill "#333333"
      c.gravity "North"
      c.pointsize 48
      c.draw "text 0,40 '#{song_name}'"
      c.pointsize 36
      c.draw "text 0,110 '#{artist_name}'"
    end

    # アルバムアート
    if album_image.present?
      begin
        album_art = MiniMagick::Image.open(album_image)
        album_art.resize "350x350"
        image = image.composite(album_art) do |c|
          c.compose "Over"
          c.gravity "Center"
          c.geometry "+0+30"
        end
      rescue => e
        Rails.logger.error "アルバム画像の処理に失敗: #{e.message}"
      end
    end

    # フッター
    image.combine_options do |c|
      c.font font_path
      c.fill "#333333"
      c.gravity "South"
      c.pointsize 36
      c.draw "text 0,-100 'MY-SONG-JOURNAL'"
      c.pointsize 24
      c.draw "text 0,-50 'og.nullnull.dev'"
    end

    Rails.logger.info "OGP image generation completed in #{Time.current - start_time} seconds"
    image
  end

  def set_cors_headers
    allowed_origins = [
      "https://ogp.buta3.net",
      "https://cards-dev.twitter.com",
      "https://twitter.com",
      "https://x.com",
      "https://www.facebook.com",
      "https://l.facebook.com"
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
