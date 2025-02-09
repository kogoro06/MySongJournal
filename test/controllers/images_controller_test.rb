require "test_helper"

class ImagesControllerTest < ActionDispatch::IntegrationTest
  test "should get ogp" do
    # 最小限のモック
    dummy_response = mock()
    dummy_response.stubs(:to_blob).returns("dummy image data")

    # generate_ogp_imageメソッドをスタブ化
    ImagesController.any_instance.stubs(:generate_ogp_image).returns(dummy_response)

    get ogp_images_path, params: {
      album_image: "https://example.com/image.jpg",
      text: "テストタイトル"
    }

    assert_response :success
    assert_equal "image/png", response.content_type
  end
end
