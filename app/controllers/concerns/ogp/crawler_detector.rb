module Ogp
  module CrawlerDetector
    extend ActiveSupport::Concern

    private

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
