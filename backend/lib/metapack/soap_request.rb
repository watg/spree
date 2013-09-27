module Metapack
  class SoapRequest
    # Make sure that a template exists with the same name as the soap action
    #   e.g, passing :find_ready_to_manifest_records as the action should have
    #        a template find_ready_to_manifest_records.xml.erb and will result
    #        in a soap action findReadyToManifestRecords
    def self.do(service_name, action, template_binding)
      Net::HTTP.start(Metapack::Config.host) {|http|
        req = Net::HTTP::Post.new(self.url(service_name))
        req.basic_auth Metapack::Config.username, Metapack::Config.password
        req["User-Agent"]    = "WATG"
        req["SOAPAction"]    = action.to_s.camelize(:lower)
        req["Content-Type"]  = "text/xml;charset=UTF-8"

        req.body = self.envelope(action, template_binding)

        Metapack::SoapResponse.new(http.request(req))
      }
    end

    def self.url(service_name)
      "#{Metapack::Config.service_base_url}/#{service_name}"
    end

    def self.envelope(template_name, template_binding)
      xml = Metapack::SoapTemplate.new(template_name, template_binding).xml
      Rails.logger.info '+'*80
      Rails.logger.info xml
      xml
    end
  end
end
