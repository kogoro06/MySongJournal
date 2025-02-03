require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "notification" do
    contact = Contact.new(
      name: "Test User",
      email: "test@example.com",
      message: "This is a test message"
    )

    mail = ContactMailer.notification(contact)
    assert_equal "【MySongJournal】新しいお問い合わせがありました", mail.subject
    assert_equal [ "mysongjournalconfirmable@gmail.com" ], mail.to
    assert_equal [ "mysongjournalconfirmable@gmail.com" ], mail.from
    assert_equal [ "test@example.com" ], mail.reply_to
  end
end
