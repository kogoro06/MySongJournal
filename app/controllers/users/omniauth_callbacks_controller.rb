# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2, :spotify ]

  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, scope: [:devise, :omniauth_callbacks, :google_oauth2]) if is_navigational_format?
    else
      Rails.logger.error "OAuth user creation failed: #{@user.errors.full_messages.join(', ')}"
      set_flash_message(:alert, :failure, scope: [:devise, :omniauth_callbacks, :google_oauth2])
      redirect_to new_user_registration_url
    end
  rescue => e
    Rails.logger.error "OAuth error: #{e.message}"
    redirect_to new_user_registration_url
  end

  # 将来的な機能拡張時に使用
  # def spotify
  #   callback_for(:spotify)
  # end

  private

  def callback_for(provider)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
    else
      Rails.logger.error "OAuth user creation failed: #{@user.errors.full_messages.join(', ')}"
      flash[:alert] = "#{provider.to_s.capitalize}認証に失敗しました。#{@user.errors.full_messages.join(', ')}"
      redirect_to new_user_registration_url
    end
  rescue => e
    Rails.logger.error "OAuth error: #{e.message}"
    redirect_to new_user_registration_url
  end

  protected

  def failure
    redirect_to root_path, alert: "認証に失敗しました。もう一度お試しください。"
  end
end
