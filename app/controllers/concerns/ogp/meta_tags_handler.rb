module Ogp
  module MetaTagsHandler
    extend ActiveSupport::Concern

    private

    def prepare_meta_tags
      if @journal.present?
        set_journal_meta_tags
      else
        set_default_meta_tags
      end
    end

    def set_journal_meta_tags
      @ogp_title = @journal.song_name.presence || default_title
      @ogp_description = @journal.artist_name.presence || default_description
      @ogp_image = generate_ogp_image_url(@journal)
      @ogp_url = journal_url(@journal)
    end

    def set_default_meta_tags
      @ogp_title = default_title
      @ogp_description = default_description
      @ogp_image = "#{request.base_url}/images/ogp.png"
      @ogp_url = request.original_url
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

    def default_title
      "MY SONG JOURNAL"
    end

    def default_description
      "音楽と一緒に日々の思い出を記録しよう"
    end
  end
end
