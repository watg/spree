module Spree
  # Wraps ShippingRate to add functionality used when displaying it.
  class ShippingRatePresenter < BasePresenter
    presents :shipping_rate
    delegate :name, :display_cost, to: :shipping_rate

    def duration
      shipping_rate.shipping_method.duration_description || ''
    end
  end
end
