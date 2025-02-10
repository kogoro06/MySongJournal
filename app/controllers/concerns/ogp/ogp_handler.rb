module Ogp
  module OgpHandler
    extend ActiveSupport::Concern
    include CrawlerDetector
    include MetaTagsHandler

    included do
      before_action :prepare_meta_tags, only: [ :show ]
    end

    private

    def prepare_meta_tags
      return unless @journal

      @ogp_title = @journal.song_name.presence || "MY SONG JOURNAL"
      @ogp_description = @journal.artist_name.presence || "音楽と一緒に日々の思い出を記録しよう"

      cache_key = @journal.updated_at.to_i.to_s

      @ogp_image = url_for(
        controller: :images,
        action: :ogp,
        text: "#{@journal.song_name} - #{@journal.artist_name}",
        album_image: @journal.album_image,
        v: cache_key
      )
    end

    def crawler?
      crawler_user_agents = [
        "Twitterbot",
        "facebookexternalhit",
        "LINE-Parts/",
        "Discordbot",
        "Slackbot",
        "bot",
        "spider",
        "crawler",
        "OGP Checker"
      ]

      crawler_referrers = [
        "ogp.buta3.net"
      ]

      user_agent = request.user_agent.to_s.downcase
      referer = request.referer.to_s.downcase

      crawler_user_agents.any? { |bot| user_agent.include?(bot.downcase) } ||
      crawler_referrers.any? { |ref| referer.include?(ref) }
    end

    def check_crawler_or_authenticate
      return if crawler?
      authenticate_user!
    end
  end
end
