module Spree
  module Api
    module Dashboard
      module Office
        # returns a formatted version of the number of
        # orders by marketing type for the dashboard api
        class FormatTodayOrdersByHour
          TODAY_RANGE = Time.zone.now.at_beginning_of_day..Time.zone.now.beginning_of_hour - 1
          def initialize(valid_orders = Spree::Order.complete.not_cancelled)
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            grouped_orders = today_orders.group_by_hour(:completed_at, range: TODAY_RANGE).count
            grouped_orders.map do |k, v|
              { x: k.to_i, y: v }
            end
          end
        end
      end
    end
  end
end
