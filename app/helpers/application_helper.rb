module ApplicationHelper
  def default_meta_tags
    {
      site: "MY SONG JOURNAL",
      og: {
        site_name: "MY SONG JOURNAL",
        type: "website",
        title: "MY SONG JOURNAL",  # タイトルは必須
        description: "音楽と一緒に日々の思い出を記録しよう",  # 説明も追加
        image: image_url("ogp.png")  # デフォルト画像
      },
      twitter: {
        card: "summary_large_image",
        site: "@study_kogoro",  # Twitterのユーザー名
        title: "MY SONG JOURNAL",  # タイトルは必須
        description: "音楽と一緒に日々の思い出を記録しよう",  # 説明も追加
        image: image_url("ogp.png")  # デフォルト画像
      }
    }
  end
end
