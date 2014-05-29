module Spree
  class ProductType < ActiveRecord::Base

    NORMAL    = 'normal'
    GIFT_CARD = 'gift_card'
    KIT       = 'kit'
    PACKAGING = 'packaging'
    DEFAULT   = NORMAL 

    def kit?
      name == KIT
    end

    def gift_card?
      name == GIFT_CARD
    end

    def self.default
      where(name: DEFAULT).first
    end

  end
end
