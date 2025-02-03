class OtherUsersController < ApplicationController
  ALLOWED_REDIRECT_HOSTS = [ "twitter.com", "x.com", "www.twitter.com", "www.x.com" ].freeze

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
    return redirect_to other_user_path(user), alert: "Xのリンクが登録されていません" unless user.x_link.present?

    begin
      uri = URI.parse(user.x_link)
      host = uri.host&.sub(/\Awww\./, "")

      if uri.scheme.in?([ "http", "https" ]) && host.in?([ "twitter.com", "x.com" ])
        redirect_to user.x_link, allow_other_host: true
      else
        redirect_to other_user_path(user), alert: "無効なXのリンクです"
      end
    rescue URI::InvalidURIError
      redirect_to other_user_path(user), alert: "無効なXのリンクです"
    end
  end
end
