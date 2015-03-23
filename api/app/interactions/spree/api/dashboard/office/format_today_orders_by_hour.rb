module Spree
  module Api
    module Dashboard
      module Office
        class FormatTodayOrdersByHour
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            today_orders = Spree::Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
            grouped_orders = today_orders.group_by_hour(:completed_at, range: Time.zone.now.at_beginning_of_day..Time.zone.now.beginning_of_hour - 1).count
            grouped_orders.map do |k,v|
              { x: k.to_i, y: v }
            end
          end

        end
      end
    end
  end
end
