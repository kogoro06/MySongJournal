class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    callback_for(:google)
  end

  def callback_for(provider)
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider.to_s.capitalize) if is_navigational_format?
    else
      Rails.logger.error "OAuth user creation failed: #{@user.errors.full_messages.join(', ')}"
      flash[:alert] = "Google認証に失敗しました。#{@user.errors.full_messages.join(', ')}"
      redirect_to new_user_registration_url
    end
  rescue => e
    Rails.logger.error "OAuth error: #{e.message}"
    flash[:alert] = "認証中にエラーが発生しました"
    redirect_to new_user_registration_url
  end

  def failure
    redirect_to root_path
  end
end