module Spree
  class LineItemPersonalisation < ActiveRecord::Base
    belongs_to :line_item, class_name: "Spree::LineItem"

    attr_accessor :presentation_id
    #store_accessor :prices
    #store_accessor :data

  end
end


