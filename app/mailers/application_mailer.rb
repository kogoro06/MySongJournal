class ApplicationMailer < ActionMailer::Base
  default from: 'mysongjournalconfirmable@gmail.com'
  layout 'mailer'

  def notification(contact)
    @contact = contact
    mail(
      subject: "新しいお問い合わせがありました",
      from: contact.email
    )
  end
end