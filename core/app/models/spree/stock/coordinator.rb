module Spree
  module Stock
    class Coordinator
      attr_reader :order

      def initialize(order)
        @order = order
      end

      def packages
        packages = build_packages
        packages = prioritize_packages(packages)
        packages = estimate_packages(packages)
        packages
      end

      # Build packages as per stock location
      #
      # It needs to check whether each stock location holds at least one stock
      # item for the order. In case none is found it wouldn't make any sense
      # to build a package because it would be empty. Plus we avoid errors down
      # the stack because it would assume the stock location has stock items
      # for the given order
      #
      # Returns an array of Package instances
      def build_packages(packages = Array.new)
        StockLocation.active.each do |stock_location|
          next unless has_any_stock_items?(stock_location, order)
          packer = build_packer(stock_location, order)
          packages += packer.packages
        end
        packages
      end

      private
      def prioritize_packages(packages)
        prioritizer = Prioritizer.new(order, packages)
        prioritizer.prioritized_packages
      end

      def estimate_packages(packages)
        estimator = Estimator.new(order)
        packages.each do |package|
          package.shipping_rates = estimator.shipping_rates(package)
        end
        packages
      end

      def build_packer(stock_location, order)
        Packer.new(stock_location, order, splitters(stock_location))
      end

      def splitters(stock_location)
        # extension point to return custom splitters for a location
        # Note this could have been overriden in initializer/spree.rb
        Rails.application.config.spree.stock_splitters
      end

      # TODO: Adjust the part bit to look for `all` instead of `any`.
      # Stock location should return true if we can satisfy a complete assembly.
      def has_any_stock_items?(stock_location, order)
        order.line_items.detect do |line|
          if line.parts.any?
            stock_location.stock_items.where(:variant_id => line.parts.pluck(:variant_id)).exists?
          else
            stock_location.stock_items.where(:variant_id => line.variant_id).exists?
          end
        end
      end

    end
  end
end
