module Spree
  class ProductType < ActiveRecord::Base

    TYPES = {
      normal:    'normal',
      gift_card: 'gift_card',
      kit:       'kit',
      pattern:   'pattern',
      packaging: 'packaging'
    }

    scope :physical, -> { where(is_digital: false) }

    def self.default
      where(name: TYPES[:normal]).first
    end

    def normal?
      name == TYPES[:normal]
    end

    def kit?
      name == TYPES[:kit]
    end

    def pattern?
      name == TYPES[:pattern]
    end

    def gift_card?
      name == TYPES[:gift_card]
    end

    def requires_supplier?
      !is_operational? and
      !is_digital? and
      !is_assembly?
    end
  end
end
