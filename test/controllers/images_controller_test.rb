require "test_helper"

class ImagesControllerTest < ActionDispatch::IntegrationTest
  include Ogp::ImageGenerator

  setup do
    # テスト用の画像ファイルが存在することを確認
    @base_image_path = Rails.root.join("app/assets/images/ogp.png")
    skip unless File.exist?(@base_image_path)
  end

  test "should get ogp" do
    get ogp_images_path, params: {
      title: "テストタイトル",
      emotion: "喜",
      song_name: "テスト曲名",
      artist_name: "テストアーティスト"
    }
    assert_response :success
    assert_equal "image/png", response.media_type
  end
end
