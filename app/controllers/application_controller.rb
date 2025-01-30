class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :set_profile
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  private

  def after_sign_in_path_for(resource)
    root_path
  end

  def set_current_user
    @current_user = current_user
  end

  def set_profile
    @profile = current_user&.profile if user_signed_in?
  end

  def after_sign_out_path_for(resource)
    root_path
  end
end
