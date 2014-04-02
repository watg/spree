module Olapic
  module Stream
    def olapic_data(url)
      Rails.cache.fetch(url, expires_in: 1.day) do
        uri = URI(url)
        query = [uri.query, "key=#{OLAPIC_API_KEY}"].compact.join('&')
        complete_url = [uri.scheme, "://", uri.host, uri.path].join + "?#{query}"
        RestClient.get(complete_url)
      end
    end

  end
end
