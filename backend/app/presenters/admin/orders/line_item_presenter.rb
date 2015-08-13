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
        _divisor = kit? ? 0 : READY_MADE_ITEM_COUNT
        _divisor += parts_quantity
        _divisor
      end

      def kit?
        item.product.kit?
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
