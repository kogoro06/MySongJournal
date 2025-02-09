module Ogp
  module MetaTagsHandler
    extend ActiveSupport::Concern

    private

    def prepare_meta_tags
      return unless @journal

      @ogp_title = @journal.song_name.presence || "MY SONG JOURNAL"
      @ogp_description = @journal.artist_name.presence || "音楽と一緒に日々の思い出を記録しよう"
      @ogp_image = generate_ogp_image_url(@journal)
      @ogp_url = journal_url(@journal)
    end

    def generate_ogp_image_url(journal)
      cache_key = "#{journal.id}-#{journal.updated_at.to_i}"

      url_for(
        controller: :images,
        action: :ogp,
        text: "#{journal.song_name} - #{journal.artist_name}",
        album_image: journal.album_image,
        v: cache_key,
        journal_id: journal.id
      )
    end
  end
end
