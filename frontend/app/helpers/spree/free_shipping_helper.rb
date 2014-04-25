module Spree
  module FreeShippingHelper

    FREE_SHIPPING_COUNTRY_CODES = {
      'US' => '$120.00',
      'CA' => '$120.00',
      'GB' => '£65.00',
      'FR' => '€70.00',
      'ES' => '€65.00'
    }

    def free_shipping?
      FREE_SHIPPING_COUNTRY_CODES.keys.include? current_country_code
    end

    def free_shipping_amount
      FREE_SHIPPING_COUNTRY_CODES[current_country_code]
    end
  end
end