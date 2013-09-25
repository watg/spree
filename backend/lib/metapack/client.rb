module Metapack
  class Client
    def create_and_allocate_consignment(consignment)
      url = Metapack::Config.service_base_url + "/AllocationService"
      Net::HTTP.start(Metapack::Config.host) {|http|
        req = Net::HTTP::Post.new(url)
        req.basic_auth Metapack::Config.username, Metapack::Config.password
        body = soap_message(:create_and_allocate_consignment, consignment)
        req["User-Agent"]    = "WATG"
        req["SOAPAction"]    = "createAndAllocateConsignments"
        req["Content-Type"]  = "text/xml;charset=UTF-8"
        req["Content-Length"]= body.size

        req.body = body
        extract(http.request(req))
      }
    end

    private
    def soap_message(name, consignment)
      xml_template = File.read(File.expand_path("../templates/#{name}.xml.erb", __FILE__))
      ERB.new(xml_template).result(binding)
    end

    def extract(response)
      if response.code.to_i == 200
        build_hash(response.body)
      else
        Rails.logger.info(response.body)
        raise "The request to Metapack failed error code: #{response.code}"
      end
    end

    def build_hash(xml)
      response = Nokogiri::XML(xml)
      {
        metapack_consignment_id: consignment_code(response)
      }
    rescue Exception => error
      Rails.logger.info(error.inspect)
      Rails.logger.info(error.backtrace)
      raise "Could not parse response from Metapack"
    end

    def consignment_code(xml_doc)
      code = xml_doc.xpath('//createAndAllocateConsignmentsReturn/consignmentCode')[0].content
      raise "Could not retreive consignment code" if code.blank?
      code 
    end
  end
end
