require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_contact_url
    assert_response :success
  end

  test "should get create" do
    assert_difference("Contact.count") do
      post contacts_url, params: { 
        contact: { 
          name: "Test User",
          email: "test@example.com",
          message: "This is a test message"
        }
      }
    end
    assert_redirected_to root_url
  end
end
