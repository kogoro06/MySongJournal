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
      song_name, artist_name = parse_text(params[:text])
      album_image = normalize_album_image(params[:album_image])

      # キャッシュキーを生成
      cache_key = generate_cache_key(song_name, artist_name, album_image)
      Rails.logger.info "Cache key: #{cache_key}"

      # キャッシュから画像データを取得または生成
      image_data = Rails.cache.fetch(cache_key, expires_in: 1.year) do
        Rails.logger.info "Cache miss - Generating new OGP image"
        generate_ogp_image_blob(song_name, artist_name, album_image)
      end

      Rails.logger.info "Image data size: #{image_data.bytesize} bytes"

      # レスポンスヘッダーの設定
      set_response_headers(image_data)

      # 条件付きGETのチェック
      if stale?(etag: response.headers["ETag"])
        Rails.logger.info "Sending image data..."
        send_data image_data, type: "image/png", disposition: "inline"
      else
        Rails.logger.info "304 Not Modified response sent"
      end
    rescue StandardError => e
      handle_error(e)
    end
  end

  private

  # パラメータから曲名とアーティスト名を抽出
  def parse_text(text)
    parts = text.to_s.split(" - ").map(&:strip)
    song_name = parts[0]
    artist_name = parts.size > 2 ? parts.last : parts[1]
    Rails.logger.info "Parsed song name: #{song_name.inspect}"
    Rails.logger.info "Parsed artist name: #{artist_name.inspect}"
    [ song_name.to_s.strip.downcase, artist_name.to_s.strip.downcase ]
  end

  # アルバム画像URLを正規化
  def normalize_album_image(album_image)
    normalized_url = album_image.to_s.split("?").first
    valid_url?(normalized_url) ? normalized_url : nil
  end

  # キャッシュキーを生成
  def generate_cache_key(song_name, artist_name, album_image)
    Digest::MD5.hexdigest([ song_name, artist_name, album_image ].join("_"))
  end

  # OGP画像を生成し、バイナリデータを返す
  def generate_ogp_image_blob(song_name, artist_name, album_image)
    image = generate_ogp_image(
      album_image: album_image,
      song_name: song_name,
      artist_name: artist_name
    )
    blob = image.to_blob
    image.destroy!
    blob
  end

  # レスポンスヘッダーを設定
  def set_response_headers(image_data)
    response.headers["Content-Type"] = "image/png"
    response.headers["Cache-Control"] = "public, max-age=31536000"
    response.headers["ETag"] = %("#{Digest::MD5.hexdigest(image_data)}")
  end

  # エラー時の処理
  def handle_error(error)
    Rails.logger.error "OGP画像生成エラー: #{error.message}"
    Rails.logger.error "Backtrace: #{error.backtrace.join("\n")}"
    Rails.logger.error "Parameters: #{params.inspect}"

    # デフォルトのOGP画像を返す
    default_ogp_path = Rails.root.join("app/assets/images/ogp.png")
    Rails.logger.info "Sending default OGP image: #{default_ogp_path}"
    send_file default_ogp_path, type: "image/png", disposition: "inline"
  end

  # 外部URLの検証
  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end

  # CORSヘッダーを設定
  def set_cors_headers
    allowed_origins = ENV.fetch("ALLOWED_ORIGINS", "").split(",")

    if allowed_origins.include?(request.headers["Origin"])
      response.headers["Access-Control-Allow-Origin"] = request.headers["Origin"]
    end

    response.headers["Access-Control-Allow-Methods"] = "GET, HEAD, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
    response.headers["Cache-Control"] = "public, max-age=31536000"
    response.headers["Expires"] = 1.year.from_now.httpdate
  end

  # OGP画像を生成
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
      c.draw "text 0,40 '#{song_name.truncate(25, separator: /\s/)}'"
      c.pointsize 36
      c.draw "text 0,110 '#{artist_name.truncate(20, separator: /\s/)}'"
    end

    # アルバムアートを追加
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

    # フッターを追加
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
end