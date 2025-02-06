module OgpCreator
  extend ActiveSupport::Concern

  def build(album_image_url = nil)
    begin
      # 基本的なOGP画像の設定
      width = 1200
      height = 630
      background_color = "white"

      # 画像を生成
      image = MiniMagick::Image.create(width: width, height: height, type: "xc:#{background_color}")

      # アルバム画像が提供されている場合は合成
      if album_image_url.present?
        begin
          # アルバム画像をダウンロード
          album_image = MiniMagick::Image.open(album_image_url)

          # アルバム画像のサイズを調整（アスペクト比を保持）
          album_size = 400
          album_image.resize "#{album_size}x#{album_size}"

          # アルバム画像を中央に配置
          x_offset = (width - album_size) / 2
          y_offset = (height - album_size) / 2

          # 画像を合成
          image.composite(album_image) do |c|
            c.compose "Over"
            c.geometry "+#{x_offset}+#{y_offset}"
          end
        rescue => e
          Rails.logger.error "Error processing album image: #{e.message}"
          # アルバム画像の処理に失敗した場合はデフォルト画像のまま続行
        end
      end

      # 画像をBLOBとして返す
      image.format "png"
      image.to_blob

    rescue => e
      Rails.logger.error "Error in OGP generation: #{e.message}"
      # エラーが発生した場合はデフォルトのOGP画像を返す
      default_ogp_path = Rails.root.join("app/assets/images/ogp.png")
      if File.exist?(default_ogp_path)
        File.binread(default_ogp_path)
      else
        raise "Default OGP image not found"
      end
    end
  end
end
