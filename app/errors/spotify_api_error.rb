# app/errors/spotify_api_error.rb
class SpotifyApiError < StandardError
    def initialize(message = "Spotify API Error")
      super(message)
    end
end
