module Spree
  module Stock
    class InventoryUnitBuilder
      def initialize(order)
        @order = order
      end

      def units
        built_units = @order.line_items.flat_map do |line_item|
          line_item.quantity.times.map do |i|
            parts = line_item.parts.reject(&:container?)
            if parts.any?
              parts.map do |part|
                part.quantity.times.map do |p|
                @order.inventory_units.build(
                  pending: true,
                  variant: part.variant,
                  line_item: line_item,
                  line_item_part: part
                )
                end
              end
            else
              @order.inventory_units.build(
                pending: true,
                variant: line_item.variant,
                line_item: line_item
              )
            end
          end
        end
        built_units.flatten
      end

    end
  end
end
