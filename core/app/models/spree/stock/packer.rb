module Spree
  module Stock
    class Packer
      attr_reader :stock_location, :order, :splitters

      def initialize(stock_location, order, splitters=[Splitter::Base])
        @stock_location = stock_location
        @order = order
        @splitters = splitters
      end

      def packages
        if splitters.empty?
          [default_package]
        else
          build_splitter.split [default_package]
        end
      end

      def default_package
        package = Package.new(stock_location, order)
        order.line_items.each do |line_item|

          if line_item.variant.should_track_inventory?
            next unless stock_location.stock_item(line_item.variant)

            on_hand, backordered = stock_location.fill_status(line_item.variant, line_item.quantity)

            on_hand.map do |item|
              package.add line_item, item.count, :on_hand, line_item.variant, item.supplier if item.count > 0
            end

            backordered.map do |item|
              package.add line_item, item.count, :backordered, line_item.variant, item.supplier if item.count > 0
            end
          else
            package.add line_item, line_item.quantity, :on_hand
          end

        end
        package
      end

      private
      def build_splitter
        splitter = nil
        splitters.reverse.each do |klass|
          splitter = klass.new(self, splitter)
        end
        splitter
      end
    end
  end
end
