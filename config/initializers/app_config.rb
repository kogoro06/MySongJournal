Rails.application.config.app_domain = case Rails.env
when "production"
  "mysongjournal.com"  # 本番環境のドメイン
when "staging"
  "staging.mysongjournal.com"  # ステージング環境のドメイン
else
  "localhost:3000"  # 開発環境のドメイン
end
