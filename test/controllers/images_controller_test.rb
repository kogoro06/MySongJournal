require "test_helper"

class ImagesControllerTest < ActionDispatch::IntegrationTest
  test "should get ogp" do
    # 最小限のモック
    dummy_response = mock()
    dummy_response.stubs(:to_blob).returns("dummy image data")
    dummy_response.stubs(:destroy!).returns(true)  # destroy!メソッドを追加

    # generate_ogp_imageメソッドをスタブ化
    ImagesController.any_instance.stubs(:generate_ogp_image).returns(dummy_response)

    get "/images/ogp.png", params: {
      album_image: "https://example.com/image.jpg",
      text: "テストタイトル - テストアーティスト"
    }

    assert_response :success
    assert_equal "image/png", response.content_type
  end

  test "should handle missing parameters" do
    # デフォルト画像のモック
    default_image = mock()
    default_image.stubs(:to_blob).returns("default image data")
    default_image.stubs(:destroy!).returns(true)

    ImagesController.any_instance.stubs(:generate_ogp_image).returns(default_image)

    get "/images/ogp.png"
    assert_response :success
    assert_equal "image/png", response.content_type
  end

  test "should handle invalid album image url" do
    # エラー時の画像のモック
    error_image = mock()
    error_image.stubs(:to_blob).returns("error image data")
    error_image.stubs(:destroy!).returns(true)

    ImagesController.any_instance.stubs(:generate_ogp_image).returns(error_image)

    get "/images/ogp.png", params: {
      album_image: "invalid-url",
      text: "テストタイトル - テストアーティスト"
    }
    assert_response :success
    assert_equal "image/png", response.content_type
  end
end
