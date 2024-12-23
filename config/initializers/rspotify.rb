# Spotify API認証をテスト環境では無効化
unless Rails.env.test?
  RSpotify.authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"])
end
