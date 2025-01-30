class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    current_user.follow(@user)
    render_updates
  end

  def destroy
    current_user.unfollow(@user)
    render_updates
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def render_updates
    # 複数のTurbo Streamを配列で返す
    render turbo_stream: [
      # フォローボタンの更新
      turbo_stream.update_all(
        ".follow-button-#{@user.id}",
        partial: "follows/button_content",
        locals: { user: @user }
      ),
      # フォロー/フォロワー数の更新
      turbo_stream.update(
        "follow-stats",
        partial: "follows/stats",
        locals: { user: current_user }
      )
    ]
  end
end
