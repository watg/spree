module Spree
  module Api
    module Dashboard
      module Office
        class FormatTodaySellsByType
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            # todo improve this query
            data = Spree::LineItem.joins(:order).merge(today_orders).group_by { |ri| ri.variant.product.marketing_type.title }.map do |key, line_items|
              {
                key => line_items.map(&:quantity).reduce(:+)
              }
            end
            data = Hash[*data.collect(&:to_a).flatten]
            data.sort_by { |_name, value| - value }.to_a
          end
        end
      end
    end
  end
end
