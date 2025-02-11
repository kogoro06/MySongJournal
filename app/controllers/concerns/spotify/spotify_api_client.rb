module Spotify::SpotifyApiClient
  extend ActiveSupport::Concern

  private

  # Spotify APIのアクセストークンを取得するメインメソッド
  def get_spotify_access_token
    if @spotify_access_token && Time.now < @spotify_access_token_expiry
      return @spotify_access_token
    end
  
    response = spotify_auth_request
    token_data = JSON.parse(response.body)
    @spotify_access_token = token_data["access_token"]
    @spotify_access_token_expiry = Time.now + token_data["expires_in"].to_i
  
    raise "Failed to get Spotify access token: #{response.body}" unless @spotify_access_token
  
    @spotify_access_token
  rescue RestClient::ExceptionWithResponse => e
    raise "Failed to get Spotify access token: #{e.response}"
  end
  
  # Spotifyの認証リクエストを送信するメソッド
  def spotify_auth_request
    RestClient.post(
      SPOTIFY_TOKEN_URL,
      auth_params,
      auth_headers
    )
  rescue RestClient::ExceptionWithResponse => e
    raise "Failed to authenticate with Spotify: #{e.response}"
  end

  # Spotify APIに送信するリクエストパラメータを定義
  def auth_params
    client_id = ENV["SPOTIFY_CLIENT_ID"]
    client_secret = ENV["SPOTIFY_CLIENT_SECRET"]

    raise "Environment variables SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET must be set" if client_id.nil? || client_secret.nil?

    {
      grant_type: "client_credentials",
      client_id: client_id,
      client_secret: client_secret
    }
  end

  # Spotify APIに送信するリクエストヘッダーを定義
  def auth_headers
    { content_type: "application/x-www-form-urlencoded" }
  end

  # SpotifyのトークンエンドポイントURLを定数として定義
  SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token".freeze
end
