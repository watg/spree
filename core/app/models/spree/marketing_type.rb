module Spree
  class MartinProductType < ActiveRecord::Base
    validates_inclusion_of :category, :in => %w(rtw kit assembly supply gift_card packaging)

    def nature
      digital? ? :digital : :physical
    end

    def kit?
      # TODO: migrate assmebly to kit
      category == 'kit' or category == 'assembly'
    end
    alias_method :kit?, :assembly?
    
    def rtw?
      category == 'rtw'
    end
    
    def gift_card?
      category == 'gift_card'
    end
    
    def pattern?
      name == 'pattern'
    end

  end
end
