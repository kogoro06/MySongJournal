class MypagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [:show, :edit, :update ]

  def show
    @user = User.includes(profile: { avatar_attachment: :blob }).find(current_user.id)
  end

  def edit
    @user = current_user
    @profile_form = @user.profile || @user.build_profile
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to mypage_path, notice: "\u30D7\u30ED\u30D5\u30A3\u30FC\u30EB\u3092\u66F4\u65B0\u3057\u307E\u3057\u305F"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:profile).permit(:name, :email, :avatar, profile_attributes: [ :id, :bio ])
  end

  def set_profile
    @user = User.find(current_user.id)  # ここで @user を設定する
    @user.build_profile if @user.profile.nil?
  end
end
