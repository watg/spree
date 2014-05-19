module Spree
  #class ProductType
  class ProductType < ActiveRecord::Base

    NORMAL    = 'normal'
    GIFT_CARD = 'gift_card'
    KIT       = 'kit'
    PACKAGING = 'packaging'
    DEFAULT   = NORMAL 

#    def self.default
#      Spree::ProductType.find_by_name DEFAULT
#    end

#    def self.gift_card?(product)
#      product.product_type.name == GIFT_CARD
#
#
#      #Spree::ProductType.find_by_name GIFT_CARD
#    end

    def kit?
      name == KIT
    end


    def gift_card?
      name == GIFT_CARD
    end


#    DEFAULT = { digital: false, promotable: true,  internal: false }
#
#    RULES = {
#      normal:    DEFAULT,
#      kit:       DEFAULT,
#      gift_card: DEFAULT.merge( digital: true, promotable: false ),
#      packaging: DEFAULT.merge( internal: true, promotable: false ),
#    }
#
#    def initialize(product)
#      type = product.product_type.to_sym
#
#      unless self.class.types.include? type
#        raise "product type: #{product.product_type} is not supported" 
#      end
#
#      @rules = RULES[type]
#    end
#
#    def self.types
#      RULES.keys
#    end
#
#    def digital?
#      rules[:digital]
#    end
#
#    def internal?
#      rules[:internal]
#    end
#
#    def promotable?
#      rules[:promotable]
#    end
#
#    private
#
#    def rules
#      @rules
#    end
#
  end
end
