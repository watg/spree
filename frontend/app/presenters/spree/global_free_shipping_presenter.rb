module Spree
  # presenter for user specific free shipping views
  class GlobalFreeShippingPresenter < SimpleBasePresenter

    def cache_key
      [currency, country_code, device]
    end

    def eligible?
      @eligible ||= promotion.eligible?
    end

    def amount
      @amount ||= Spree::Money.new(promotion.amount, currency: currency).to_html
    end

    def shipping_partial
      "/spree/shared/shipping/shipping_#{country_code.downcase}"
    end

    private

    def promotion
      @promotion ||= Spree::Promotable::GlobalFreeShipping.new(
        country_code, currency
      ).eligible_promotion
    end
  end
end
