require "test_helper"

class OtherusersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get otherusers_show_url
    assert_response :success
  end
end
