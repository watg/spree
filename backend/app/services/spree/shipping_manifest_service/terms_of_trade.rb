module Spree
  class ShippingManifestService
    # Work out the shipping terms of trade to send to metapack to indicate who
    # pays for shipping duty.
    class TermsOfTrade < ActiveInteraction::Base
      model :order, class: Spree::Order

      def execute
        case
        when shipping_to_canada? && order.order_type.party?
          "DDP" # duty paid by watg
        when shipping_to_usa?
          "DDP" # duty paid by watg
        else
          "DDU" # duty unpaid
        end
      end

      private

      def shipping_to_usa?
        (Spree::Country.where(iso: ["US"]).to_a).include?(order.ship_address.country)
      end

      def shipping_to_canada?
        (Spree::Country.where(iso: ["CA"]).to_a).include?(order.ship_address.country)
      end
    end
  end
end
