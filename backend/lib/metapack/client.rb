module Metapack
  class Client
    UNKOWN_TRACKING_URL = ["NotKnown"]

    def self.create_and_allocate_consignment_with_booking_code(consignment)
      response = request(:AllocationService, :create_and_allocate_consignments_with_booking_code, consignment: consignment)
      {
        metapack_consignment_code: response.find("consignmentCode"),
        tracking:                  tracking_info(response),
        metapack_status:           response.find("status"),
        carrier:                   response.find("carrierCode")
      }
    end

    def self.create_labels_as_pdf(consignment_id)
      response = request(:ConsignmentService, :create_labels_as_pdf, consignment_code: consignment_id)
      Base64.decode64(response.find("createLabelsAsPdfReturn"))
    end

    def self.find_ready_to_manifest_records
      manifests = request(:ManifestService, :find_ready_to_manifest_records).find_all(
        "findReadyToManifestRecordsReturn findReadyToManifestRecordsReturn",
        ["carrierCode", "consignmentCount", "parcelCount"]
      )
      manifests.map do |manifest|
        {
          carrier: manifest["carrierCode"],
          consignment_count: manifest["consignmentCount"],
          parcel_count: manifest["parcelCount"],
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
        message = "/!\\ #{response.find('faultstring')} /!\\"

        raise message
      end

      response
    end

    private
    def self.tracking_info(result)
      parcels = result.find_all("parcels", ['reference', 'trackingCode', 'trackingUrl'])
      # there is parcels tag that is the list and each item is also called parcels! so there a double match
      parcels.drop(1).map {|p|
        tracking_url = p["trackingUrl"].include?("UNKOWN_TRACKING_URL") ? nil : p["trackingUrl"]
          {
            reference:              p['reference'],
            metapack_tracking_code: p['trackingCode'],
            metapack_tracking_url:  tracking_url(p)
          }
        }
    end

    def self.tracking_url(parcel)
      parcel["trackingUrl"].include?("UNKOWN_TRACKING_URL") ? nil : parcel["trackingUrl"]
    end
  end
end
