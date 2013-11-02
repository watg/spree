module Spree
  class Personalisation < ActiveRecord::Base

    belongs_to :product, class_name: 'Spree::Product'

    def name
      self.class.name.split('::').last.downcase
    end

    def price_in(currency)
      prices[currency]
    end

    def subunit_price_in(currency)
      price_in(currency) * 100
    end

  end
end
 
