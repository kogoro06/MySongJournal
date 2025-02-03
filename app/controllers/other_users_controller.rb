class OtherUsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    unless @user
      flash[:alert] = "ユーザーが見つかりません"
      redirect_to root_path
      return
    end

    flash.now[:notice] = "Xのアイコンを登録してください" if params[:show_notice].present? && !@user.x_link.present?

    @journals = @user.journals.order(created_at: :desc).page(params[:page]).per(3)
    @liked_journals = @user.liked_journals.order(created_at: :desc).page(params[:page]).per(3)
  end

  def x_redirect
    user = User.find(params[:id])
    redirect_url = user.x_link

    return redirect_to other_user_path(user), alert: "Xのリンクが登録されていません" unless redirect_url.present?

    safe_url = ::MySongJournal::Whitelist::Domains.build_safe_url(:x, redirect_url)

    if safe_url.present?
      redirect_to safe_url, allow_other_host: true
    else
      redirect_to other_user_path(user), alert: "無効なURLです"
    end
  end
end
