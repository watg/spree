module Spree
  module FreeShippingHelper

    FREE_SHIPPING_COUNTRY_CODES = {
      'US' => '$250.00',
      #'CA' => '$250.00',
      'GB' => '£100.00',
      'FR' => '€200.00',
      'ES' => '€200.00',
      #'CH' => '$250.00'
    }

    def free_shipping?
      FREE_SHIPPING_COUNTRY_CODES.keys.include? current_country_code
    end

    def free_shipping_amount
      FREE_SHIPPING_COUNTRY_CODES[current_country_code]
    end

    def free_shipping_to_uk?
      current_country_code == 'GB'
    end
  end
end
