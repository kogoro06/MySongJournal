module Whitelist
  module Domains
    SOCIAL = {
      x: {
        domains: ["twitter.com", "x.com"],
        schemes: ["https"]
      }
    }.freeze

    def self.allowed_domains_for(service)
      SOCIAL.dig(service, :domains) || []
    end

    def self.allowed_schemes_for(service)
      SOCIAL.dig(service, :schemes) || []
    end
  end
end