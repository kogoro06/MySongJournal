module Spotify::SpotifyApiRequestable
  extend ActiveSupport::Concern

  private

  MAX_ATTEMPTS = 3

  def spotify_get(endpoint, params = {})
    token = get_spotify_access_token
    response = RestClient.get(
      "https://api.spotify.com/v1/#{endpoint}",
      default_headers(token).merge(params)
    )
    JSON.parse(response.body)
  rescue RestClient::Unauthorized
    handle_unauthorized_access
  end

  def default_headers(token)
    {
      Authorization: "Bearer #{token}",
      "Accept-Language" => "ja"
    }
  end

  def handle_unauthorized_access(endpoint, params)
    @attempts ||= 0
    @attempts += 1
    if @attempts < MAX_ATTEMPTS
      spotify_get(endpoint, params)
    else
      raise "Unauthorized access after multiple attempts"
    end
  end
end
