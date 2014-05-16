module Spree
  class MarketingType < ActiveRecord::Base

    # def nature
    #   digital? ? :digital : :physical
    # end

    def kit?
      # run rename_assembly_to_kit_for_marketing_type.rb
      category == 'kit' or category == 'assembly'
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
