module Spotify::SpotifyApiRequestable
  extend ActiveSupport::Concern

  private

  # 最大リトライ回数を定数として定義
  # APIリクエストが失敗した場合に、最大で3回までリトライします。
  MAX_ATTEMPTS = 3

  # Spotify APIにGETリクエストを送信するメソッド
  # 指定されたエンドポイントに対してリクエストを送り、レスポンスをJSON形式で返します。
  def spotify_get(endpoint, params = {})
    attempts = 0 # リトライ回数をカウントする変数

    begin
      # アクセストークンを取得します（キャッシュがあればそれを使用）。
      token = get_spotify_access_token

      # Spotify APIにGETリクエストを送信します。
      response = RestClient.get(
        "https://api.spotify.com/v1/#{endpoint}", # Spotify APIのエンドポイントURL
        default_headers(token).merge(params)      # リクエストヘッダーとパラメータを結合
      )

      # レスポンスをJSON形式に変換して返します。
      JSON.parse(response.body)
    rescue RestClient::Unauthorized
      # 401 Unauthorizedエラーが発生した場合の処理
      attempts += 1
      if attempts < MAX_ATTEMPTS
        # アクセストークンをクリアして再取得し、リトライします。
        Rails.logger.warn("Unauthorized access. Retrying... Attempt #{attempts} of #{MAX_ATTEMPTS}")
        @spotify_access_token = nil
        retry
      else
        # 最大リトライ回数を超えた場合はエラーを発生させます。
        raise "Unauthorized access after #{MAX_ATTEMPTS} attempts"
      end
    rescue RestClient::ExceptionWithResponse => e
      # その他のエラーが発生した場合の処理
      # エラー内容をログに記録し、エラーを発生させます。
      error_message = e.response.body
      Rails.logger.error("Spotify API request failed: #{error_message}. Endpoint: #{endpoint}, Params: #{params}")
      raise "Spotify API request failed: #{error_message}"
    end
  end

  # Spotify APIに送信するリクエストヘッダーを定義
  # アクセストークンを含むヘッダーを設定します。
  def default_headers(token)
    {
      Authorization: "Bearer #{token}", # アクセストークンをAuthorizationヘッダーに設定
      "Accept-Language" => "ja"        # レスポンスの言語を日本語に設定
    }
  end
end
