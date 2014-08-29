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

    def requires_supplier?
      !is_operational? and
      !is_digital? and
      !is_assembly?
    end

  end
end
