namespace :spotify do
  desc "Spotifyトークンを定期的にリフレッシュ"
  task refresh_tokens: :environment do
    SpotifyToken.refresh_all_tokens
    puts "✅ Spotifyトークンが全てリフレッシュされました。"
  end
end
