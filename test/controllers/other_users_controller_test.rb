require "test_helper"

class OtherUsersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get other_users_show_url
    assert_response :success
  end
end
