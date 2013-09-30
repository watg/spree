module Metapack
  class Client
    def self.create_and_allocate_consignment(consignment)
      response = request(:AllocationService, :create_and_allocate_consignments, consignment: consignment)
      {
        metapack_consignment_id: result.find("consignmentCode"),
        tracking:                tracking_info(result)
      }
    end

    def self.create_labels_as_pdf(consignment_id)
      response = request(:ConsignmentService, :create_labels_as_pdf, consignment_code: consignment_id)
      Base64.decode64(response.find("createLabelsAsPdfReturn"))
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

    def self.create_manifest(carrier)
      create_response = request(:ManifestService, :create_manifest, carrier: carrier)
      manifest_code = create_response.find("createManifestReturn createManifestReturn")
      print_response = request(:ManifestService, :create_manifest_as_pdf, manifest: manifest_code)
      Base64.decode64(print_response.find("createManifestAsPdfReturn"))
    end

    def self.request(service, action, context = {})
      response = Metapack::SoapRequest.do(service, action, context)

      if !response.success?
        Rails.logger.info(response.body)
        raise "The request to Metapack failed"
      end

      response
    end

    private
    def self.tracking_info(result)
      parcels = result.find_all("parcels", ['reference', 'trackingCode', 'trackingUrl'])
      # there is parcels tag that is the list and each item is also called parcels! so there a double match
      parcels.drop(1).map {|p|
          {
            reference:              p['reference'],
            metapack_tracking_code: p['trackingCode'],
            metapack_tracking_url:  p['trackingUrl']
          }
        }
    end
  end
end
