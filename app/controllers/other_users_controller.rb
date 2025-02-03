class OtherUsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @user_name = @user.name
    # 自分自身のページにアクセスしようとした場合、リダイレクト
    if @user == current_user
      redirect_to mypage_path
      return
    end

    @journals = @user.journals.order(created_at: :desc).page(params[:page]).per(3)
    @liked_journals = @user.liked_journals.order(created_at: :desc).page(params[:page]).per(3)
  end

  def x_redirect
    user = User.find(params[:id])
    x_link = user.safe_x_link
    
    if x_link.present?
      redirect_to x_link, allow_other_host: true
    else
      redirect_to user_path(user), alert: 'Xのリンクが登録されていません'
    end
  end
end
