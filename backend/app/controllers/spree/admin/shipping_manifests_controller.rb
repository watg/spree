module Spree
  module Admin

    class ShippingManifestsController < Spree::Admin::BaseController
      def index
        @manifests = Metapack::Client.find_ready_to_manifest_records
      end

      def create
        carrier = params[:carrier]
        pdf = Metapack::Client.create_manifest(carrier)
        send_data pdf, disposition: :inline, filename: "#{carrier}-manifest.pdf", type: "application/pdf"
      end
    end
  end
end
