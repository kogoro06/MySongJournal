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
    # テスト用の日記データを作成
    journal = journals(:one)  # fixtureを使用する場合

    # OGP画像生成のパラメータを設定
    get ogp_images_url(format: :png), params: {
      title: journal.title,
      emotion: journal.emotion,
      song_name: journal.song_name,
      artist_name: journal.artist_name
    }

    assert_response :success
    assert_equal "image/png", response.content_type
  end
end
