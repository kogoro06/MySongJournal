require "rest-client"
require "json"

class SpotifyToken < ApplicationRecord
  belongs_to :user, optional: true

  # バリデーション
  validates :access_token, presence: true
  validates :refresh_token, presence: true, length: { minimum: 50 }
  validates :expires_at, presence: true

  # トークンが期限切れかどうかを確認
  def expired?
    expires_at.present? && expires_at < Time.current
  end

  # アクセストークンを更新するメソッド
  def refresh_access_token
    response = RestClient.post(
      "https://accounts.spotify.com/api/token",
      {
        grant_type: "refresh_token",
        refresh_token: refresh_token
      },
      {
        Authorization: "Basic #{Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")}",
        content_type: "application/x-www-form-urlencoded"
      }
    )

    data = JSON.parse(response.body)

    update!(
      access_token: data["access_token"],
      expires_at: Time.current + data["expires_in"].to_i.seconds
    )

    Rails.logger.info "✅ アクセストークンが正常にリフレッシュされました。"
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "❌ Spotify API Error: #{e.response}"
    raise "Failed to refresh access token"
  rescue StandardError => e
    Rails.logger.error "❌ 予期しないエラー: #{e.message}"
    raise
  end

  # アクセストークンが無効であればリフレッシュ
  def ensure_valid_token
    refresh_access_token if expired?
  end

  # 全てのトークンをリフレッシュ
  def self.refresh_all_tokens
    SpotifyToken.find_each do |token|
      next unless token.expired?

      Rails.logger.info "🔄 トークンをリフレッシュ中: User ID #{token.user_id}"
      token.refresh_access_token
    rescue StandardError => e
      Rails.logger.error "❌ User ID #{token.user_id} のトークンリフレッシュ中にエラーが発生しました: #{e.message}"
    end
  rescue StandardError => e
    Rails.logger.error "❌ トークンの一括リフレッシュ中にエラーが発生しました: #{e.message}"
  end
end
