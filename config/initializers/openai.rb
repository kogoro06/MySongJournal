require 'openai'

OpenAI.configure do |config|
  config.access_token = ENV['OPENAI_API_KEY']
  config.request_timeout = 240
  # OpenAIの初期化設定を追加
  config.max_retries = 3
  config.retry_interval = 1
end