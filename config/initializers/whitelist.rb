module MySongJournal
module Whitelist
  module Domains
      SOCIAL = {
        x: {
          domains: [ "twitter.com", "x.com" ],
          schemes: [ "https" ]
        }
      }.freeze

      def self.allowed_domains_for(service)
        SOCIAL.dig(service, :domains) || []
      end

      def self.allowed_schemes_for(service)
        SOCIAL.dig(service, :schemes) || []
      end

      def self.build_safe_url(service, url)
        return nil unless url.present?

        begin
          uri = URI.parse(url)
          host = uri.host&.sub(/\Awww\./, "")
          scheme = uri.scheme
          path = uri.path
          query = uri.query

          return nil unless allowed_schemes_for(service).include?(scheme)
          return nil unless allowed_domains_for(service).include?(host)

          # URLを安全に再構築
          safe_uri = URI::HTTPS.build(
            host: host,
            path: path,
            query: query
          )
          safe_uri.to_s
        rescue URI::InvalidURIError
          nil
        end
      end
  end
end
end
