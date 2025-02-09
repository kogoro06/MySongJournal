require "test_helper"

class ImagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    # ベース画像のパス
    @base_image_path = Rails.root.join("app/assets/images/ogp.png")
    @font_path = Rails.root.join("app/assets/fonts/DelaGothicOne-Regular.ttf")

    # ベース画像が存在することを確認
    assert File.exist?(@base_image_path), "Base image not found at #{@base_image_path}"
    assert File.exist?(@font_path), "Font file not found at #{@font_path}"

    # テスト用の画像データを準備
    @dummy_image = File.binread(@base_image_path)
  end

  test "should get ogp" do
    # テストパラメータを直接指定
    get ogp_images_url(format: :png), params: {
      title: "テスト日記",
      emotion: "喜",
      song_name: "テスト曲",
      artist_name: "テストアーティスト"
    }

    assert_response :success
    assert_equal "image/png", response.content_type
  end
end
