module Spree

  class ShippingManifestService::TermsOfTrade < ActiveInteraction::Base

    model :order, class: 'Spree::Order'

    def execute
      if shipping_to_usa?
        'DDP' # duty paid by watg
      else
        'DDU' # duty unpaid
      end
    end

    private
    def shipping_to_usa?
      (Spree::Country.where(iso: ['US']).to_a).include?(order.ship_address.country)
    end

  end

end
