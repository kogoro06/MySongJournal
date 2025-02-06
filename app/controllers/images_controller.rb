class ImagesController < ApplicationController
  include OgpCreator
  skip_before_action :authenticate_user!, raise: false

  def ogp
    begin
      # パラメータを安全に取得
      album_image_url = params[:album_image].presence
      text = params[:text].presence

      # OGP画像を生成（テキストも渡す）
      image_data = build(album_image_url, text)

      # レスポンスを返す
      send_data image_data, type: "image/png", disposition: "inline"
    rescue => e
      Rails.logger.error "Error in OGP endpoint: #{e.message}"
      # エラーが発生した場合はデフォルトのOGP画像を返す
      default_ogp_path = Rails.root.join("app/assets/images/ogp.png")
      if File.exist?(default_ogp_path)
        send_file default_ogp_path, type: "image/png", disposition: "inline"
      else
        head :internal_server_error
      end
    end
  end
end
