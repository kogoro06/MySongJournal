module Spotify::SpotifyApiRequestable
  extend ActiveSupport::Concern
  require "rest-client"

  private

  def spotify_get(endpoint, params = {})
    token = get_spotify_access_token
    response = RestClient.get(
      "https://api.spotify.com/v1/#{endpoint}",
      default_headers(token).merge(params)
    )
    JSON.parse(response.body)
  rescue RestClient::Unauthorized
    token = get_spotify_access_token
    response = RestClient.get(
      "https://api.spotify.com/v1/#{endpoint}",
      default_headers(token).merge(params)
    )
    JSON.parse(response.body)
  end

  def default_headers(token)
    {
      Authorization: "Bearer #{token}",
      "Accept-Language" => "ja"
    }
  end
end