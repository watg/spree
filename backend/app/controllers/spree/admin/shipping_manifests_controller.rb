module Spree
  module Admin

    class ShippingManifestsController < Spree::Admin::BaseController
      def index
        @manifests = Metapack::Client.find_ready_to_manifest_records
      end
    end

  end
end
