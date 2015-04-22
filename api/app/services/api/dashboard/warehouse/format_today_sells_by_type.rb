module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of the todays sells by type for the dashboard api
      class FormatTodaySellsByType
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.complete.not_cancelled
          @orders = valid_orders
        end

        def run
          data = sells_records.map do |key, line_items|
            { key => line_items.map(&:quantity).reduce(:+) }
          end
          Hash[*data.collect(&:to_a).flatten].sort_by { |_name, value| - value }
        end

        private

        def sells_records
          Spree::LineItem.joins(:order).merge(today_orders) # TODO, improve this query
            .group_by { |ri| ri.variant.product.marketing_type.title }
        end

        def today_orders
          Api::Dashboard::Warehouse::FindTodayValidOrders.new(@orders).run
        end
      end
    end
  end
end