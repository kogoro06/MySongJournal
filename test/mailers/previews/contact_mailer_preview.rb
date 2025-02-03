# Preview all emails at http://localhost:3000/rails/mailers/contact_mailer
class ContactMailerPreview < ActionMailer::Preview
  def notification
    contact = Contact.new(
      name: "テストユーザー",
      email: "test@example.com",
      message: "これはテストメッセージです。"
    )
    ContactMailer.notification(contact)
  end
end
