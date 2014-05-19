module Spree
  class MartinProductType < ActiveRecord::Base
    validates_inclusion_of :category, :in => %w(rtw kit assembly supply gift_card packaging)

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
