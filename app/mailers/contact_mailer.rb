class ContactMailer < ApplicationMailer
  default to: "mysongjournalconfirmable@gmail.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.contact_mailer.notification.subject
  #
  def notification(contact)
    begin
      Rails.logger.info "メール送信開始: #{contact.email}"
      @contact = contact
      mail(
        to: "mysongjournalconfirmable@gmail.com",
        subject: "【MySongJournal】新しいお問い合わせがありました",
        from: "mysongjournalconfirmable@gmail.com",
        reply_to: contact.email
      ) do |format|
        format.html
      end
      Rails.logger.info "メール送信完了"
    rescue => e
      Rails.logger.error "メール送信エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end
end
