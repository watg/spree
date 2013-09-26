module Metapack
  class Client
    def self.create_and_allocate_consignment(consignment)
      result = request(:AllocationService, :create_and_allocate_consignments, consignment: consignment)
      {
        metapack_consignment_id: result.find("consignmentCode")
      }
    end

    def self.find_ready_to_manifest_records
      manifests = request(:ManifestService, :find_ready_to_manifest_records).find_all(
        "findReadyToManifestRecordsReturn findReadyToManifestRecordsReturn",
        ["carrierCode", "consignmentCount"]
      )
      manifests.map do |manifest|
        {
          carrier: manifest["carrierCode"],
          parcel_count: manifest["consignmentCount"]
        }
      end
    end

    def self.request(service, action, context = {})
      response = Metapack::SoapRequest.do(service, action, context)

      if !response.success?
        Rails.logger.info(response.body)
        raise "The request to Metapack failed"
      end

      response
    end
  end
end
