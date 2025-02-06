module ApplicationHelper
  def default_meta_tags
    {
      site: "MY SONG JOURNAL",
      title: "",
      noindex: !Rails.env.production?,
      og: {
        site_name: "MY SONG JOURNAL",
        type: "website",
        image: image_url("ogp.png")
      },
      twitter: {
        card: "summary_large_image"
      }
    }
  end
end
