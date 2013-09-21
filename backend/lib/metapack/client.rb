module Metapack
  class Client
    def create_and_allocate_consignment(consignment)
      url = Metapack::Config.service_base_url + "/allocationService"
      Net::HTTP.start(Metapack::Config.host) {|http|
        req = Net::HTTP::Post.new(url)
        req.basic_auth Metapack::Config.username, Metapack::Config.password
        req.body = soap_message(:create_and_allocate_consignment, consignment)
        extract(http.request(req))
      }
    end

    private
    def soap_message(name, consignment)
      xml_template = File.read(File.expand_path("../templates/#{name}.xml.erb", __FILE__))
      ERB.new(xml_template).result(binding)
    end

    def extract(response)
      # check http status code 200 or raise error
      # consignment_code =
      # response.body[:create_and_allocate_consignments_response]
      #              [:create_and_allocate_consignments_return]
      #              [:create_and_allocate_consignments_return]
      #              [:consignment_code]

      if response.code.to_i == 200
        build_hash(response.body)
      else
        Rails.logger.info(response.inspect)
        raise "The request to Metapack failed error code: #{response.code}"
      end
    end

    def build_hash(xml)
      Hash.from_xml(response.body)["soap:Envelope"]["soap:Body"].inject({}) do |result, elem|
        result[:metapack_consignment_id] = elem["createAndAllocateConsignmentsResponse"]
        ['createAndAllocateConsignmentsReturn']
        ['createAndAllocateConsignmentsReturn']
        ['consignmentCode']
        result
      end
    rescue Exception => error
      Rails.logger.info(xml.inspect)
      raise "Could not parse response from Metapack"
    end
  end
end
