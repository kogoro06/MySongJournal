class MypagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [ :show, :edit, :update ]

  def show
    @user = current_user

    # タブに応じて表示する投稿を切り替え
    case params[:tab]
    when "liked_posts"
      @journals = []  # 自分の投稿は空配列に
      @liked_journals = current_user.liked_journals
                                  .includes(:user)
                                  .order(created_at: :desc)
                                  .page(params[:page])
                                  .per(3)
    else
      @journals = current_user.journals
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
          partial: "mypages/posts_content",
          locals: {
            journals: @journals,
            liked_journals: @liked_journals
          }
        )
      end
    end
  end

  def edit
    @user = current_user
    @profile_form = @user.profile || @user.build_profile
  end

  def update
    @user = current_user
    @profile_form = @user.profile || @user.build_profile
    if @user.update(user_params)
      redirect_to mypage_path, notice: "\u30D7\u30ED\u30D5\u30A3\u30FC\u30EB\u3092\u66F4\u65B0\u3057\u307E\u3057\u305F"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:profile).permit(:name, :email, :avatar, :bio, :x_link)
  end

  def set_profile
    @user = User.find(current_user.id)  # ここで @user を設定する
    @user.build_profile if @user.profile.nil?
  end
end
