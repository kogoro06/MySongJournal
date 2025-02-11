module Spotify::SpotifyApiClient
  extend ActiveSupport::Concern

  private

  # Spotify APIのアクセストークンを取得するメインメソッド
  # アクセストークンはSpotify APIを利用する際に必要な認証情報です。
  def get_spotify_access_token
    # ミューテックス（Mutex）を使用してスレッドセーフにする
    # 複数のスレッドが同時にこのメソッドを実行しても、データの競合を防ぎます。
    @token_mutex ||= Mutex.new
    @token_mutex.synchronize do
      # キャッシュされたアクセストークンが有効であれば、それをそのまま返します。
      # これにより、毎回アクセストークンを取得する無駄を省きます。
      if @spotify_access_token && Time.now < @spotify_access_token_expiry
        return @spotify_access_token
      end

      # アクセストークンを取得するためにSpotifyの認証エンドポイントにリクエストを送信します。
      response = spotify_auth_request
      token_data = JSON.parse(response.body)

      # レスポンスからアクセストークンと有効期限を取得してキャッシュします。
      @spotify_access_token = token_data["access_token"]
      @spotify_access_token_expiry = Time.now + token_data["expires_in"].to_i

      # アクセストークンが取得できなかった場合はエラーを発生させます。
      raise "Failed to get Spotify access token: #{response.body}" unless @spotify_access_token

      # 取得したアクセストークンを返します。
      @spotify_access_token
    end
  rescue RestClient::ExceptionWithResponse => e
    # Spotify APIからエラーが返ってきた場合は、その内容を含むエラーを発生させます。
    raise "Failed to get Spotify access token: #{e.response}"
  end

  # Spotifyの認証リクエストを送信するメソッド
  # Spotifyのアクセストークンを取得するために必要なリクエストを送信します。
  def spotify_auth_request
    RestClient.post(
      SPOTIFY_TOKEN_URL, # SpotifyのトークンエンドポイントURL
      auth_params,       # リクエストのパラメータ（クライアントIDやシークレットなど）
      auth_headers       # リクエストのヘッダー（Content-Typeなど）
    )
  rescue RestClient::ExceptionWithResponse => e
    # 認証リクエストが失敗した場合はエラーを発生させます。
    raise "Failed to authenticate with Spotify: #{e.response}"
  end

  # Spotify APIに送信するリクエストパラメータを定義
  # クライアントIDとクライアントシークレットを環境変数から取得し、リクエストパラメータとして設定します。
  def auth_params
    client_id = ENV["SPOTIFY_CLIENT_ID"]
    client_secret = ENV["SPOTIFY_CLIENT_SECRET"]

    # クライアントIDやシークレットが設定されていない場合はエラーを発生させます。
    raise "Environment variables SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET must be set" if client_id.nil? || client_secret.nil?

    {
      grant_type: "client_credentials", # クライアント認証のための固定値
      client_id: client_id,             # 環境変数から取得したクライアントID
      client_secret: client_secret      # 環境変数から取得したクライアントシークレット
    }
  end

  # Spotify APIに送信するリクエストヘッダーを定義
  # Content-Typeを指定して、リクエストが正しく処理されるようにします。
  def auth_headers
    { content_type: "application/x-www-form-urlencoded" }
  end

  # SpotifyのトークンエンドポイントURLを定数として定義
  # Spotifyのアクセストークンを取得するためのエンドポイントです。
  SPOTIFY_TOKEN_URL = "https://accounts.spotify.com/api/token".freeze
end
