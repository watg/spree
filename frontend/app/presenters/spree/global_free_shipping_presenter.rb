module Spree
  # presenter for user specific free shipping views
  class GlobalFreeShippingPresenter < SimpleBasePresenter
    def eligible?
      @eligible ||= promotion.eligible?
    end

    def amount
      @amount ||= Spree::Money.new(promotion.amount, currency: currency).to_html
    end

    def shipping_partial
      partials = Spree::Promotable::GlobalFreeShipping::SHIPPING_PARTIALS
      if partials.include?(country_code.downcase)
        "/spree/shared/shipping/shipping_#{country_code.downcase}"
      else
        "/spree/shared/shipping/default_shipping"
      end
    end

    private

    def promotion
      @promotion ||= Spree::Promotable::GlobalFreeShipping.new(
        country_code, currency
      ).eligible_promotion
    end
  end
end
