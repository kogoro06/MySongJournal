class OgpCreator
  require "mini_magick"
  BASE_IMAGE_PATH = Rails.root.join("app/assets/images/ogp.png").to_s
  FONT_PATH = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf").to_s
  IMAGE_WIDTH = 1200
  IMAGE_HEIGHT = 630
  ALBUM_IMAGE_SIZE = 400
  ALBUM_Y_OFFSET = 130

  def self.build(text = nil, album_image_url = nil)
    Rails.logger.info "=== OGP Image Generation Debug Info ==="
    Rails.logger.info "Album URL: #{album_image_url.inspect}"

    # ベース画像を読み込む
    base_image = MiniMagick::Image.open(BASE_IMAGE_PATH)
    base_image.resize "#{IMAGE_WIDTH}x#{IMAGE_HEIGHT}"

    # アルバム画像の追加（存在する場合）
    if album_image_url.present?
      begin
        Rails.logger.info "Downloading album image..."
        album_image = MiniMagick::Image.open(album_image_url)
        album_image.resize "#{ALBUM_IMAGE_SIZE}x#{ALBUM_IMAGE_SIZE}"

        # 一時ファイルに保存
        temp_album = Tempfile.new([ "album", ".png" ])
        album_image.write(temp_album.path)

        # 画像を合成
        base_image = base_image.composite(MiniMagick::Image.open(temp_album.path)) do |c|
          c.compose "Over"
          c.geometry "+#{(IMAGE_WIDTH - ALBUM_IMAGE_SIZE) / 2}+#{ALBUM_Y_OFFSET}"
        end
        Rails.logger.info "Album image composited successfully"
      rescue => e
        Rails.logger.error "Failed to process album image: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      ensure
        temp_album&.close
        temp_album&.unlink
      end
    end

    base_image.format "png"
    result = base_image.to_blob

    # 画像サイズをログに出力
    size_in_mb = (result.bytesize.to_f / 1024 / 1024).round(2)
    Rails.logger.info "Generated OGP image size: #{size_in_mb}MB"

    result
  rescue => e
    Rails.logger.error "Error in OgpCreator.build: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
