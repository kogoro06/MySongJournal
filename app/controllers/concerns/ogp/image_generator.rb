module Ogp
  module ImageGenerator
    extend ActiveSupport::Concern

    class Generator
      require "mini_magick"

      # 定数の定義
      BASE_IMAGE_PATH = Rails.root.join("app/assets/images/ogp.png").to_s
      FONT_PATH = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf").to_s
      FONT_SIZE = 35
      SUBTITLE_FONT_SIZE = 30
      IMAGE_WIDTH = 1200
      IMAGE_HEIGHT = 630
      ALBUM_IMAGE_SIZE = 350
      ALBUM_Y_OFFSET = 150
      TITLE_Y_OFFSET = 800
      SUBTITLE_Y_OFFSET = 500

      def self.build(text, album_image_url = nil)
        Rails.cache.fetch([ "ogp_image", text, album_image_url ], expires_in: 1.week) do
          new(text, album_image_url).generate
        end
      rescue => e
        Rails.logger.error "Error in OGP image generation: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise
      end

      def initialize(text, album_image_url)
        @text = text
        @album_image_url = album_image_url
        @title = "Today's song"
        @subtitle = text.sub(/^Today's song\s*/, "").strip
      end

      def generate
        create_base_image
        add_album_image if @album_image_url.present?
        add_text_layers
        @result.to_blob
      end

      private

      def create_base_image
        @base_image = MiniMagick::Image.open(BASE_IMAGE_PATH)
        @base_image.resize "#{IMAGE_WIDTH}x#{IMAGE_HEIGHT}"
      end

      def add_album_image
        album_image = MiniMagick::Image.open(@album_image_url)
        album_image.resize "#{ALBUM_IMAGE_SIZE}x#{ALBUM_IMAGE_SIZE}"

        temp_album = Tempfile.new([ "album", ".png" ])
        album_image.write(temp_album.path)

        @base_image = @base_image.composite(MiniMagick::Image.open(temp_album.path)) do |c|
          c.compose "Over"
          c.geometry "+#{(IMAGE_WIDTH - ALBUM_IMAGE_SIZE) / 2}+#{ALBUM_Y_OFFSET}"
        end
      rescue => e
        Rails.logger.error "Failed to process album image: #{e.message}"
        raise
      ensure
        temp_album&.close
        temp_album&.unlink
      end

      def add_text_layers
        temp_base = Tempfile.new([ "base", ".png" ])
        @base_image.write(temp_base.path)

        @result = MiniMagick::Image.open(temp_base.path)
        add_title
        add_subtitle
      ensure
        temp_base&.close
        temp_base&.unlink
      end

      def add_title
        @result.combine_options do |c|
          c.gravity "south"
          c.font FONT_PATH
          c.pointsize FONT_SIZE
          c.fill "black"
          c.annotate "+0+#{TITLE_Y_OFFSET}", @title
        end
      end

      def add_subtitle
        @result.combine_options do |c|
          c.gravity "south"
          c.font FONT_PATH
          c.pointsize SUBTITLE_FONT_SIZE
          c.fill "black"
          c.annotate "+0+#{SUBTITLE_Y_OFFSET}", @subtitle
        end
      end
    end
  end
end
