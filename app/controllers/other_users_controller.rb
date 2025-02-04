class OtherUsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    unless @user
      flash[:alert] = "ユーザーが見つかりません"
      redirect_to root_path
      return
    end

    flash.now[:notice] = "Xのアイコンを登録してください" if params[:show_notice].present? && !@user.x_link.present?

    # タブの状態を保存（ページネーションの場合は保存しない）
    if params[:tab].present? && !params[:page].present?
      session[:other_user_tab] = params[:tab]
    end

    # デフォルトのタブを設定
    session[:other_user_tab] ||= "my_posts"

    # タブに応じて表示する投稿を切り替え
    case session[:other_user_tab]
    when "liked_posts"
      @journals = []  # 投稿は空配列に
      @liked_journals = @user.liked_journals
                            .includes(:user)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(3)
    else
      @journals = @user.journals
                      .includes(:user)
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(3)
      @liked_journals = []  # いいねした投稿は空配列に
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("posts_content",
          partial: "posts_content",
          locals: { journals: @journals, liked_journals: @liked_journals }
        )
      end
    end
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
