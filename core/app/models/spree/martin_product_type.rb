module Spree
  class MartinProductType < ActiveRecord::Base
    validates_inclusion_of :category, :in => %w(rtw assembly supply gift_card packaging)

    def nature
      digital? ? :digital : :physical
    end

    def assembly?
      category == 'assembly'
    end
    
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
