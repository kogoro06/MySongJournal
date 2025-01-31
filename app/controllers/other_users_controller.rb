class OtherUsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    
    # 自分自身のページにアクセスしようとした場合、リダイレクト
    if @user == current_user
      redirect_to mypage_path
      return
    end

    @journals = @user.journals.order(created_at: :desc).page(params[:page]).per(3)
    @liked_journals = @user.liked_journals.order(created_at: :desc).page(params[:page]).per(3)
  end
end
