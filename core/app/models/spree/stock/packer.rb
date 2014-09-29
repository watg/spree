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
          [product_assembly_package]
        else
          build_splitter.split [product_assembly_package]
        end
      end

      def product_assembly_package
        package = Spree::Stock::Package.new(stock_location, order)

        supplier_stock = Spree::Stock::SupplierQuantifier.new(order, stock_location)

        order.line_items.each do |line_item|

          parts = line_item.parts.stock_tracking
          if parts.any?

            parts.each do |part|
              quantity = line_item.quantity * part.quantity
              add_item_to_package(package, supplier_stock, part, quantity, line_item, part )
            end

          else
            add_item_to_package(package, supplier_stock, line_item, line_item.quantity, line_item, nil)
          end

        end
        package

      end

      private

      def add_item_to_package(package, supplier_stock, item, quantity_needed, line_item, part)

        supplier_items = supplier_stock.pop!(item.variant, quantity_needed)

        supplier_items.each do |supplier_item|
          package.add( line_item, supplier_item.quantity, supplier_item.state,
                      item.variant, supplier_item.supplier, part )

        end

      end

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
