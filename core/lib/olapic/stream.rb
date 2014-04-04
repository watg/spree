module Olapic
  module Stream
    def olapic_data(url, params)
      params ||= {}
      uri = URI(url)
      query = params.map {|a| a.join('=') }.join('&')
      complete_url = [uri.scheme, "://", uri.host, uri.path].join + "?#{query}"

      Rails.cache.fetch(complete_url, expires_in: 1.day) do
        params[:api_key] = OLAPIC_API_KEY
        query = params.map {|a| a.join('=') }.join('&')
        complete_url = [uri.scheme, "://", uri.host, uri.path].join + "?#{query}"

        RestClient.get(complete_url)
      end
    end
  end
end
