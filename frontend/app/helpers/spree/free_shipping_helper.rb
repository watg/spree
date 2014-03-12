module Spree
  module FreeShippingHelper

    FREE_SHIPPING_COUNTRY_CODES = {
      'US' => '$175.00', 
      'CA' => '$175.00', 
      'UK' => '£95.00', 
      'FR' => '€125.00', 
      'SP' => '€65.00'
    }
    

    def free_shipping?
      FREE_SHIPPING_COUNTRY_CODES.keys.include? current_country_code
    end

    def free_shipping_amount
      FREE_SHIPPING_COUNTRY_CODES[current_country_code]
    end
  end
end
