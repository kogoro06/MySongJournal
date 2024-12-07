require "test_helper"

class JournalsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers # Deviseのヘルパーをインクルード

  setup do
    @user = users(:one) # users.ymlのユーザーを使用
    sign_in @user # テストユーザーでサインイン
  end

  test "should get new" do
    get new_journal_url
    assert_response :success
  end

  test "should get index" do
    get journals_url
    assert_response :success
  end
end
