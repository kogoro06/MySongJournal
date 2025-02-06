module OgpCreator
  extend ActiveSupport::Concern

  def build(album_image_url = nil, text = nil)
    begin
      # 基本的なOGP画像の設定
      width = 1200
      height = 630
      background_color = "white"

      # 画像を生成
      image = MiniMagick::Tool::Convert.new do |convert|
        convert << "xc:#{background_color}"
        convert.size "#{width}x#{height}"
        convert << "png:-"
      end
      image = MiniMagick::Image.read(image)

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
        end
      end

      # テキストを追加（テキストが提供されている場合）
      if text.present?
        begin
          font_path = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf").to_s
          
          image.combine_options do |c|
            c.font font_path
            c.fill "black"
            c.gravity "north"
            
            # テキストを安全に分割
            lines = text.to_s.split("\n").map { |line| 
              line.gsub(/(['"\\])/, '\\\\\1') # エスケープ処理を強化
            }
            
            # タイトル（Today's song）
            if lines[0].present?
              c.pointsize 35
              c.draw %Q{text 0,40 "#{lines[0]}"}
            end
            
            # 曲名とアーティスト名
            if lines[1].present? && lines[2].present?
              c.pointsize 30
              c.draw %Q{text 0,90 "#{lines[1]}  #{lines[2]}"}
            end
          end
        rescue => e
          Rails.logger.error "Error adding text to image: #{e.message}"
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
