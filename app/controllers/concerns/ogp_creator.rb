class OgpCreator
  require 'mini_magick'  
  BASE_IMAGE_PATH = Rails.root.join('app/assets/images/ogp.png').to_s
  GRAVITY = 'center'
  TEXT_POSITION = '0,0'
  FONT_EN = Rails.root.join('app/assets/fonts/Bungee-Regular.ttf').to_s
  FONT_JA = Rails.root.join('app/assets/fonts/DelaGothicOne-Regular.ttf').to_s
  FONT_SIZE = 65
  INDENTION_COUNT = 16
  ROW_LIMIT = 8

  def self.build(text)
    Rails.logger.debug "Building image with text: #{text}"
    Rails.logger.debug "Base image path: #{BASE_IMAGE_PATH}"

    # ベース画像の存在チェック
    unless File.exist?(BASE_IMAGE_PATH)
      Rails.logger.error "Base image not found at: #{BASE_IMAGE_PATH}"
      raise "Base image not found"
    end

    # フォントの選択（日本語文字が含まれているかどうかで判断）
    font = text.match?(/[ぁ-んァ-ン一-龥]/) ? FONT_JA : FONT_EN
    Rails.logger.debug "Selected font: #{font}"

    # フォントファイルの存在チェック
    unless File.exist?(font)
      Rails.logger.error "Font file not found at: #{font}"
      raise "Font file not found"
    end

    text = prepare_text(text)
    Rails.logger.debug "Prepared text: #{text}"

    # 画像生成処理
    MiniMagick::Tool::Convert.new do |convert|
      convert << BASE_IMAGE_PATH
      convert.gravity GRAVITY
      convert.pointsize FONT_SIZE
      convert.font font
      convert.fill '#000000'
      convert.draw "text #{TEXT_POSITION} '#{text}'"
      convert << "png:-"
    end
  end

  private
  def self.prepare_text(text)
    text.to_s.scan(/.{1,#{INDENTION_COUNT}}/)[0...ROW_LIMIT].join("\n")
  end
end