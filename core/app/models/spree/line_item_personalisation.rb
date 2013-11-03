module Spree
  class LineItemPersonalisation < ActiveRecord::Base
    belongs_to :line_item, class_name: "Spree::LineItem"
    belongs_to :personalisation, class_name: "Spree::Personalisation"

    attr_accessor :presentation_id

    def self.generate_uuid( personalisations_params )
      uuids = personalisations_params.sort.map do |pp|
        array = pp[:data].sort.flatten
        array.unshift pp[:personalisation_id]
        array.join('-')
      end
      uuids.join(':')
    end

    def text
      "#{personalisation.name.capitalize} - #{personalisation.selected_data_to_text( data )}"
    end

  end
end


