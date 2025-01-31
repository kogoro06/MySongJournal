require "test_helper"

class OtherUsersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    user = users(:one) # 適切なfixtureを使用
    get other_user_path(user)
    assert_response :success
  end
end
