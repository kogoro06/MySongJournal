module ApplicationHelper
  def default_meta_tags
    {
      site: "MY SONG JOURNAL",
      og: {
        site_name: "MY SONG JOURNAL",
        type: "website"
      },
      twitter: {
        card: "summary_large_image"
      }
    }
  end
end
