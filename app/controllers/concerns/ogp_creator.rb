class OgpCreator
  require "mini_magick"
  BASE_IMAGE_PATH = Rails.root.join("app/assets/images/ogp.png").to_s
  FONT_PATH = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf").to_s
  FONT_SIZE = 35
  SUBTITLE_FONT_SIZE = 30  # サブタイトル（曲名と歌手名）用のフォントサイズ
  IMAGE_WIDTH = 1200
  IMAGE_HEIGHT = 630
  ALBUM_IMAGE_SIZE = 300
  ALBUM_Y_OFFSET = 150
  TITLE_Y_OFFSET = 70    # "Today's song" の位置
  SUBTITLE_Y_OFFSET = 20  # 曲名と歌手名の位置

  def self.build(text, album_image_url = nil)
    Rails.logger.info "=== OGP Image Generation Debug Info ==="
    Rails.logger.info "Input text: #{text.inspect}"
    Rails.logger.info "Album URL: #{album_image_url.inspect}"

    # テキストを2行に分割
    title = "Today's song"
    subtitle = text.sub(/^Today's song\s*/, "").strip

    # ベース画像の作成
    image = MiniMagick::Image.new(BASE_IMAGE_PATH)
    image.resize "#{IMAGE_WIDTH}x#{IMAGE_HEIGHT}"

    # アルバム画像の追加（存在する場合）
    if album_image_url.present?
      begin
        album_image = MiniMagick::Image.open(album_image_url)
        album_image.resize "#{ALBUM_IMAGE_SIZE}x#{ALBUM_IMAGE_SIZE}"

        result = image.composite(album_image) do |c|
          c.compose "Over"
          c.geometry "+#{(IMAGE_WIDTH - ALBUM_IMAGE_SIZE) / 2}+#{ALBUM_Y_OFFSET}"
        end
        Rails.logger.info "Album image successfully added"
      rescue => e
        Rails.logger.error "Failed to process album image: #{e.message}"
        result = image
      end
    else
      result = image
    end

    # テキストの追加
    temp_file = Tempfile.new([ "ogp", ".png" ])
    temp_file.binmode
    temp_file.write(result.to_blob)
    temp_file.rewind

    begin
      output = MiniMagick::Tool::Convert.new do |convert|
        convert << temp_file.path

        # "Today's song" を描画
        convert.gravity "south"
        convert.font FONT_PATH
        convert.pointsize FONT_SIZE
        convert.fill "black"
        convert.annotate "+0+#{TITLE_Y_OFFSET}", title

        # 曲名と歌手名を描画
        convert.gravity "south"
        convert.font FONT_PATH
        convert.pointsize SUBTITLE_FONT_SIZE
        convert.fill "black"
        convert.annotate "+0+#{SUBTITLE_Y_OFFSET}", subtitle

        convert << "png:-"
      end

      output
    ensure
      temp_file.close
      temp_file.unlink
    end
  rescue => e
    Rails.logger.error "Error in OgpCreator.build: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
