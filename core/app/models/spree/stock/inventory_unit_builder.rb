module Spree
  module Stock
    class InventoryUnitBuilder
      attr_reader :line_items, :order

      def initialize(order)
        @order      = order
        @line_items = order.line_items
      end

      def units
        line_items
          .flat_map{ |line_item| build(line_item) }
          .flatten
      end

      private

      def build(line_item)
        line_item.quantity.times.map do |i|
          if line_item.container?
            build_inventory_units_for_parts(line_item)
          else
            [
              build_inventory_units_for_line_item(line_item),
              build_inventory_units_for_parts(line_item)
            ].flatten
          end
        end
      end

      def parts(line_item)
        line_item.parts.reject(&:container?)
      end

      def build_inventory_units_for_parts(line_item)
        parts(line_item).map do |part|
          part.quantity.times.map do
            build_unit(variant: part.variant, line_item: line_item, line_item_part: part)
          end
        end
      end

      def build_inventory_units_for_line_item(line_item)
        build_unit(variant: line_item.variant, line_item: line_item)
      end

      def build_unit(opts)
        opts = default_opts.merge(opts)
        inventory_units.build(opts)
      end

      def inventory_units
        order.inventory_units
      end

      def default_opts
        { pending: true }
      end
    end
  end
end
