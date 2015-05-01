module Spree
  # Wraps ShippingRate to add functionality used when displaying it.
  class ShippingRatePresenter < BasePresenter
    presents :shipping_rate
    delegate :name, :cost, :adjustment_total, to: :shipping_rate

    def duration
      description = shipping_rate.shipping_method.shipping_method_duration.
      extend(ShippingMethodDurations::Description).dynamic_description
      description || ""
    end

    def free?
      cost + adjustment_total == 0
    end

    def display_cost
      free? ? "FREE" : shipping_rate.display_cost
    end
  end
end
