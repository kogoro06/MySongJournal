module ApplicationHelper
  def default_meta_tags
    base_url = "https://mysongjournal.com"
    page_url = @journal.present? ? "#{base_url}/journals/#{@journal.id}" : base_url

    {
      site: "MY SONG JOURNAL",
      title: "",
      reverse: true,
      separator: "|",
      description: "音楽と一緒に日々の思い出を記録しよう",
      keywords: "日記,音楽,Spotify",
      canonical: page_url,
      noindex: !Rails.env.production?,
      og: {
        site_name: "MY SONG JOURNAL",
        title: @journal&.song_name.presence || "MY SONG JOURNAL",
        description: @journal&.artist_name.presence || "音楽と一緒に日々の思い出を記録しよう",
        type: "article",
        url: page_url,
        image: "#{base_url}/ogp.png",
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        title: @journal&.song_name.presence || "MY SONG JOURNAL",
        description: @journal&.artist_name.presence || "音楽と一緒に日々の思い出を記録しよう"
      }
    }
  end
end
