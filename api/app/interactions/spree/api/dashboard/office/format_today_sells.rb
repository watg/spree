module Spree
  module Api
    module Dashboard
      module Office
        # returns a formatted version of the number of sells by currency type for the dashboard api
        class FormatTodaySells
          def initialize(valid_orders = Spree::Order.complete.not_cancelled)
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            grouped_orders = today_orders.group_by(&:currency)
            current_currencies = { "EUR" => 0, "GBP" => 0, "USD" => 0 }
            grouped_orders.each_with_object(current_currencies) do |(currency, orders), h|
              h[currency] = orders.map(&:total).reduce(:+)
              h
            end
          end
        end
      end
    end
  end
end
