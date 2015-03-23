module Spree
  module Api
    module Dashboard
      module Office
        class FormatTodaySells
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            today_orders.group_by(&:currency).inject('EUR' => 0, 'GBP' => 0, 'USD' => 0) do |h, (currency, orders)|
              h[currency] = orders.map(&:total).reduce(:+)
              h
            end
          end
        end
      end
    end
  end
end
