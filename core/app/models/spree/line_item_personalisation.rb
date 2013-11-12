module Spree
  class LineItemPersonalisation < ActiveRecord::Base
    belongs_to :line_item, class_name: "Spree::LineItem"
    belongs_to :personalisation, class_name: "Spree::Personalisation"
    #belongs_to :personalisation_including_deleted, class_name: "Spree::Personalisation", :with_deleted => true

    delegate :name, :to => :personalisation_including_deleted

    def personalisation_including_deleted
      Spree::Personalisation.with_deleted.find personalisation_id 
    end

    def self.generate_uuid( personalisations_params )
      personalisations_params ||= []
      uuids = personalisations_params.sort.map do |pp|
        array = pp[:data].sort.flatten
        array.unshift pp[:personalisation_id]
        array.join('-')
      end
      uuids.join(':')
    end

    def text
      "#{personalisation_including_deleted.name.capitalize} - #{personalisation_including_deleted.selected_data_to_text( data )}"
    end

    def data_to_text
      personalisation_including_deleted.selected_data_to_text( data )
    end

  end
end


