class ContactMailer < ApplicationMailer
  default to: 'mysongjournalconfirmable@gmail.com'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.contact_mailer.notification.subject
  #
  def notification(contact)
    @contact = contact
    mail(
      subject: "【MySongJournal】新しいお問い合わせがありました",
      from: @contact.email
    )
  end
end
