class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      begin
        # メール送信を同期的に実行して即座にエラーを確認
        ContactMailer.notification(@contact).deliver_now
        flash[:notice] = "お問い合わせありがとうございます。"
        redirect_to root_path
      rescue => e
        Rails.logger.error "メール送信エラー: #{e.message}"
        flash[:alert] = "メールの送信に失敗しました。しばらく経ってから再度お試しください。"
        render :new
      end
    else
      render :new
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :message)
  end
end
