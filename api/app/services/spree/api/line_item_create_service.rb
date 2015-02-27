module Spree
  module Api
    class LineItemCreateService < ActiveInteraction::Base

      model   :order, class: 'Spree::Order'
      model   :variant, class: 'Spree::Variant'
      integer :quantity, default: 1
      hash    :options, strip: false

      def execute
        if order.completed? and order.shipments.empty?
          stock_location_id = Spree::StockLocation.active.first.id
          order.shipments.create(stock_location_id: stock_location_id)
        end

        order.contents.add( variant, quantity || 1, options )

      end
    end
  end
end


