class ImagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def ogp
    text = params[:text]
    album_image_url = params[:album_image]

    Rails.logger.info "=== OGP Controller Debug Info ==="
    Rails.logger.info "Received text parameter: #{text.inspect}"
    Rails.logger.info "Received album_image parameter: #{album_image_url.inspect}"

    begin
      # ベース画像の存在確認
      base_image_path = Rails.root.join("app/assets/images/ogp.png")
      unless File.exist?(base_image_path)
        Rails.logger.error "Base image not found at: #{base_image_path}"
        render plain: "Error: Base image not found", status: :not_found
        return
      end

      # 画像生成
      image_data = OgpCreator.build(text, album_image_url)

      if image_data.nil?
        Rails.logger.error "Generated image data is nil"
        render plain: "Error: Failed to generate image", status: :internal_server_error
        return
      end

      Rails.logger.info "OGP image generated successfully"
      send_data image_data, type: "image/png", disposition: "inline"
    rescue => e
      Rails.logger.error "Failed to generate OGP image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      head :internal_server_error
    end
  end

  private

  def ogp_params
    params.permit(:text, :album_image)
  end
end
