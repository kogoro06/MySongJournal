class ImagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def ogp
    text = ogp_params[:text]
    Rails.logger.debug "Text parameter: #{text}"

    begin
      image_data = OgpCreator.build(text)
      Rails.logger.debug "Image generated successfully"
      
      if image_data.nil?
        Rails.logger.error "Image data is nil"
        render plain: "Error: Image generation failed", status: :internal_server_error
        return
      end

      send_data image_data, type: 'image/png', disposition: 'inline'
    rescue => e
      Rails.logger.error "Error generating image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render plain: "Error: #{e.message}", status: :internal_server_error
    end
  end

  private

  def ogp_params
    params.permit(:text)
  end
end