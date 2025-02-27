require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # WAF設定
    config.middleware.use Rack::Attack

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Asia/Tokyo"
    # config.eager_load_paths << Rails.root.join("extras")
    ENV["SPOTIFY_REDIRECT_URI"] ||= ENV["SPOTIFY_REDIRECT_URI_LOCAL"] if Rails.env.development?
    ENV["SPOTIFY_REDIRECT_URI"] ||= ENV["SPOTIFY_REDIRECT_URI_PRODUCTION"] if Rails.env.production?
    config.i18n.default_locale = :ja
    config.active_job.queue_adapter = :sidekiq
  end
end
