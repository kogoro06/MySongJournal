class ApplicationController < ActionController::Base
  before_action :set_current_user
  before_action :set_profile
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :crawler?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def crawler?
    user_agent = request.user_agent.to_s.downcase
    crawler_patterns = [
      'twitterbot',
      'facebookexternalhit',
      'line-parts/',
      'discordbot',
      'slackbot',
      'bot',
      'spider',
      'crawler'
    ]
    crawler_patterns.any? { |pattern| user_agent.include?(pattern) }
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
