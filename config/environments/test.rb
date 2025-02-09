require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Enable eager loading in CI environments
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{1.hour.to_i}" }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Disable caching for Action Mailer templates even if Action Controller caching is enabled.
  config.action_mailer.perform_caching = false

  # The :test delivery method accumulates sent emails in the ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "www.example.com" }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # ✅ Spotify API認証をスキップ
  ENV["SPOTIFY_CLIENT_ID"] ||= "test_client_id"
  ENV["SPOTIFY_CLIENT_SECRET"] ||= "test_client_secret"
  ENV["SPOTIFY_REDIRECT_URI_LOCAL"] ||= "http://localhost:3000/callback"

  # Spotify API認証を無効化
  config.after_initialize do
    if Rails.env.test?
      module SpotifyMock
        def self.authenticate(*args)
          puts "Spotify authentication skipped in test environment"
        end
      end

      RSpotify.singleton_class.prepend(SpotifyMock)
    end
  end

  # 一時ファイルの保存先を設定
  config.active_storage.service = :test
  config.tmp_path = Rails.root.join("tmp")
end
