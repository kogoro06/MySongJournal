module Spotify::SpotifyApiClient
  extend ActiveSupport::Concern

  private

  def get_spotify_access_token
    response = spotify_auth_request
    JSON.parse(response.body)["access_token"]
  end

  def spotify_auth_request
    RestClient.post(
      "https://accounts.spotify.com/api/token",
      auth_params,
      auth_headers
    )
  end

  def auth_params
    {
      grant_type: "client_credentials",
      client_id: ENV["SPOTIFY_CLIENT_ID"],
      client_secret: ENV["SPOTIFY_CLIENT_SECRET"]
    }
  end

  def auth_headers
    { content_type: "application/x-www-form-urlencoded" }
  end
end
