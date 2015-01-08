module Spree
  module Stock
    class WaitingUnitsProcessor

      attr_accessor :stock_item

      def initialize(stock_item)
        @stock_item = stock_item
        @orders_to_update = Set.new
      end

      # TODO: may be worth calling this every couple of hours with a scheduled task
      def perform(quantity)

        return unless quantity > 0

        process_waiting_inventory_units(quantity)

        update_orders
      end

      private

      def process_waiting_inventory_units(quantity)
        waiting_units = waiting_inventory_units(quantity)
        waiting_units.group_by(&:shipment).each do |shipment, units|

          stock_item.with_lock do

            # Only those that make the transition from 'backordered' or
            # 'awaiting_feed' to on_hand will be returned.
            # This deals with an edge case where between grabbing the units
            # and processing them that something has changed
            on_hand = units.select(&:fill_waiting_unit)

            stock_allocator = stock_allocator(shipment)
            stock_allocator.unstock_on_hand(stock_item.variant, on_hand)

          end

          @orders_to_update << shipment.order
        end
      end


      def update_orders
        @orders_to_update.each { |o| o.update! }
      end

      def stock_allocator(shipment)
        Spree::Stock::Allocator.new(shipment)
      end

      def waiting_inventory_units(quantity)
        Spree::InventoryUnit.waiting_for_stock_item(stock_item).first(quantity)
      end

    end
  end
end
