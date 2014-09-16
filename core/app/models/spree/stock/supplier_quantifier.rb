module Spree
  module Stock
    class SupplierQuantifier

      ON_HAND = :on_hand
      BACKORDERED = :backordered

      SupplierItem = Struct.new(:supplier, :state, :quantity)

      def initialize(order, stock_location)
        @order = order
        @stock_location = stock_location
        @hopper = stock_by_supplier
      end

      def pop!(variant, quantity)

        if variant.should_track_inventory?

          # TODO: do we need to bother about below
          #  if @stock_location.stock_item(item.variant)
          items = @hopper[variant] || []

          if items.size < quantity
            if item = @stock_location.stock_items_backorderable(variant).first
              (quantity - items.size).times { items << [item.supplier, BACKORDERED] }
            end
          end

          popped_items = items.pop(quantity)
          format_items(popped_items)
        else
          item = @stock_location.first_on_hand(variant)
          [ SupplierItem.new( item.supplier, ON_HAND, quantity) ]
        end

      end

      private

      # {5344=>[70, 70], 4253=>[98, 98, 98, 98], 4254=>[98, 98, 98, 98], 5348=>[77], 5386=>[108]}}
      def stock_by_supplier
        required_stock.inject({}) do |hash, stock|
          variant, quantity = stock
          on_hand = @stock_location.fill_status(variant, quantity)

          on_hand.map do |item|
            hash[variant] ||= []
            hash[variant] += Array.new(item.count) { [item.supplier, ON_HAND] }
          end

          hash
        end
      end

      # Return a flattened list of variants and the required quantities from 
      # the whole order
      def required_stock
        hash = Hash.new(0)
        @order.line_items.each do |line_item|

          parts = line_item.parts.stock_tracking
          if parts.any?
            parts.each do |part|
              add_to_hash(hash, part, part.quantity * line_item.quantity)
            end
          else
            add_to_hash(hash, line_item, line_item.quantity)
          end

        end

        hash
      end

      def add_to_hash(h, item, quantity)

        if item.variant.should_track_inventory?
          h[item.variant] += quantity
        end

      end

      # From:
      # [ 'fred', :on_hand ],
      # [ 'fred', :backordered ]
      #
      # To:
      # { supplier: 'fred', type: :on_hand, count: 1  },
      # { supplier: 'fred', type: :backordered, count: 1  }
      #
      def format_items(items)
        grouped = items.reduce(Hash.new(0)) do |hash, item|
          hash[item] += 1
          hash
        end
        grouped.map { |item, count| SupplierItem.new(item[0], item[1], count) }
      end


    end
  end
end
