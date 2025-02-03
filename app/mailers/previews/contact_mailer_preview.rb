# app/mailers/previews/contact_mailer_preview.rb を作成
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