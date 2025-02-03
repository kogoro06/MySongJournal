require "test_helper"

class ImagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # ベース画像のパス
    @base_image_path = Rails.root.join("app/assets/images/ogp.png")
    @font_path = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf")

    # ベース画像が存在することを確認
    assert File.exist?(@base_image_path), "Base image not found at #{@base_image_path}"
    assert File.exist?(@font_path), "Font file not found at #{@font_path}"
  end

  test "should get ogp" do
    Rails.logger.info "=== Starting OGP Test ==="
    Rails.logger.info "Base image path: #{@base_image_path}"
    Rails.logger.info "Font path: #{@font_path}"

    text = "Today's song 🎵 Test Song by Test Artist 🎤"
    album_image = "https://example.com/image.jpg"

    get "/images/ogp.png", params: { text: text, album_image: album_image }
    
    if response.status == 500
      Rails.logger.error "Response body: #{response.body}"
      Rails.logger.error "Response headers: #{response.headers}"
    end

    assert_response :success
    assert_equal "image/png", response.content_type
  end
end
