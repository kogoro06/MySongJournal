module ApplicationHelper
  def default_meta_tags
    {
      og: {
        title: "MY SONG JOURNAL",
        site_name: "MY SONG JOURNAL",
        type: "website"
      },
      twitter: {
        card: "summary_large_image"
      }
    }
  end
end
