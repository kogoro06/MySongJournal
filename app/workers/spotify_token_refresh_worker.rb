class SpotifyTokenRefreshWorker
  include Sidekiq::Worker

  def perform
    Rails.logger.info "🔄 Sidekiq: Spotifyトークンの定期リフレッシュを開始"
    SpotifyToken.refresh_all_tokens
    Rails.logger.info "✅ Sidekiq: Spotifyトークンの定期リフレッシュが完了"
  end
end
