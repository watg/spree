require 'httparty'

module Spree
  class Alert
    def self.current(host)
      params = {
        version: Spree.version,
        name: Spree::Store.current.name,
        host: host,
        rails_env: Rails.env,
        rails_version: Rails.version
      }

      # Stop sending data to spree!
      # HTTParty.get('http://alerts.spreecommerce.com/alerts.json', body: params).parsed_response
    end
  end
end
