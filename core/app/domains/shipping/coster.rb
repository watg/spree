module Shipping
  # provides cost details of selected shipping rate
  class Coster
    attr_accessor :shipments

    def initialize(shipments)
      @shipments = shipments
    end

    def promo_total
      selected_shipping_rates_sum(&:promo_total)
    end

    def included_tax_total
      selected_shipping_rates_sum(&:included_tax_total)
    end

    def additional_tax_total
      selected_shipping_rates_sum(&:additional_tax_total)
    end

    def adjustment_total
      selected_shipping_rates_sum(&:adjustment_total)
    end

    def cost
      selected_shipping_rates_sum(&:cost)
    end

    def discounted_cost
      cost + promo_total
    end

    def total
      cost + adjustment_total
    end

    def tax_total
      included_tax_total + additional_tax_total
    end

    def final_price
      cost + adjustment_total
    end

    private

    def selected_shipping_rates_sum
      shipments.to_a.select(&:selected_shipping_rate).sum do |shipment|
        yield shipment.selected_shipping_rate
      end
    end
  end
end
