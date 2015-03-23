module Spree
  module Api
    module Dashboard
      module Office
        class FormatTodayItems
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            { total: Spree::LineItem.joins(:order).merge(today_orders).to_a.map(&:quantity).reduce(:+) }
          end
        end
      end
    end
  end
end
