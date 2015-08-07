module Admin
  module Orders
    class LineItemPresenter
      attr_reader :item, :shipment

      def initialize(item, shipment)
        @item     = item
        @shipment = shipment
      end

      def quantity
        line_item_units.count / divisor
      end

      private

      def line_item_units
        item
          .inventory_units
          .select{ |iu| iu.shipment == shipment }
      end

      def divisor
        if ready_made? && parts?
          parts_quantity + [item].size
        elsif parts?
          parts_quantity
        else
          default
        end
      end

      def ready_made?
        item
          .product
          .normal?
      end

      def parts?
        item.parts.any?
      end

      def parts_quantity
        ready_made_parts.sum(&:quantity)
      end

      def ready_made_parts
        item
          .line_item_parts
          .reject(&:container?)
      end

      def default
        1
      end
    end
  end
end
