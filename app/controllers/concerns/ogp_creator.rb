class OgpCreator
  require "mini_magick"
  BASE_IMAGE_PATH = Rails.root.join("app/assets/images/ogp.png").to_s
  FONT_PATH = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf").to_s
  FONT_SIZE = 35
  SUBTITLE_FONT_SIZE = 30
  IMAGE_WIDTH = 1200
  IMAGE_HEIGHT = 630
  ALBUM_IMAGE_SIZE = 350
  ALBUM_Y_OFFSET = 150  # 100から150に変更してアルバムの位置を下げる
  # テキスト位置の調整（下からの距離を増やす）
  TITLE_Y_OFFSET = 800    # 70から150に変更
  SUBTITLE_Y_OFFSET = 500  # 20から80に変更

  def self.build(text, album_image_url = nil)
    Rails.logger.info "=== OGP Image Generation Debug Info ==="
    Rails.logger.info "Input text: #{text.inspect}"
    Rails.logger.info "Album URL: #{album_image_url.inspect}"

    title = "Today's song"
    subtitle = text.sub(/^Today's song\s*/, "").strip

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
        temp_album = Tempfile.new(['album', '.png'])
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

    # 一時ファイルに保存
    temp_base = Tempfile.new(['base', '.png'])
    base_image.write(temp_base.path)

    begin
      # テキストを追加
      result = MiniMagick::Image.open(temp_base.path)
      
      # タイトルを追加
      result.combine_options do |c|
        c.gravity "south"
        c.font FONT_PATH
        c.pointsize FONT_SIZE
        c.fill "black"
        c.annotate "+0+#{TITLE_Y_OFFSET}", title
      end

      # サブタイトルを追加
      result.combine_options do |c|
        c.gravity "south"
        c.font FONT_PATH
        c.pointsize SUBTITLE_FONT_SIZE
        c.fill "black"
        c.annotate "+0+#{SUBTITLE_Y_OFFSET}", subtitle
      end

      # 最終画像をバイナリで返す
      result.to_blob
    ensure
      temp_base.close
      temp_base.unlink
    end
  rescue => e
    Rails.logger.error "Error in OgpCreator.build: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end