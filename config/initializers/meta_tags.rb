# frozen_string_literal: true

# Meta tags configuration
MetaTags.configure do |config|
  # タイトルの制限
  config.title_limit = 70
  config.truncate_site_title_first = false

  # 説明文の制限
  config.description_limit = 160

  # キーワードの設定
  config.keywords_limit = 255
  config.keywords_separator = ", "
  config.keywords_lowercase = true

  # メタタグの設定
  config.open_meta_tags = true
  config.minify_output = false
end
