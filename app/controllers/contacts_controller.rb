class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      # メール送信を追加
      ContactMailer.notification(@contact).deliver_later
      flash[:notice] = 'お問い合わせありがとうございます。'
      redirect_to root_path
    else
      render :new
    end
  end
  private

  def contact_params
    params.require(:contact).permit(:name, :email, :message)
  end
end