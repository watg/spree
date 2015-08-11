module Admin
  module Orders
    class LineItemPresenter
      attr_reader :item, :shipment

      READY_MADE_ITEM_COUNT = 1

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
        _divisor = ready_made? ? READY_MADE_ITEM_COUNT : 0
        _divisor += parts_quantity
        _divisor
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
    end
  end
end
