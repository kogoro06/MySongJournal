module ApplicationHelper
  def default_meta_tags
    {
      site: "MySongJournal",
      title: "音楽と一緒に綴る日記アプリ",
      reverse: true,
      separator: "|",
      description: "音楽と一緒に日々の思い出を記録しよう",
      keywords: "日記,音楽,Spotify",
      canonical: request.original_url,
      noindex: !Rails.env.production?,
      og: {
        site_name: "MySongJournal",
        title: "音楽と一緒に綴る日記アプリ",
        description: "音楽と一緒に日々の思い出を記録しよう",
        type: "website",
        url: request.original_url,
        image: image_url("ogp.png"),
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        site: "@study_kogoro"
      }
    }
  end
end
