module Spree
  class LineItemPersonalisation < ActiveRecord::Base
    belongs_to :line_item, class_name: "Spree::LineItem"
    belongs_to :personalisation, class_name: "Spree::Personalisation"

    delegate :name, :to => :personalisation

    def personalisation
      Spree::Personalisation.unscoped{ super }
    end

    def text
      "#{personalisation.name.capitalize} - #{data_to_text}"
    end

    def data_to_text
      personalisation.selected_data_to_text( data )
    end

  end
end


