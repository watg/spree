module Spree
  module Feed
    class InventoryUnitRequirement

      def list
        inventory_units_inject({}) do |feeds, variant, location|
          feeds[location] ||= Hash.new(0)
          feeds[location][variant] += 1
          feeds
        end
      end

      private

      def inventory_units_inject(acc, &block)
        units = Spree::InventoryUnit.awaiting_feed.
          includes(shipment: [:stock_location]).
          includes(:variant)
        units.each do |iu|
          variant = iu.variant
          location = iu.shipment.stock_location
          acc = yield(acc, variant, location)
        end
        acc
      end
    end
  end
end
