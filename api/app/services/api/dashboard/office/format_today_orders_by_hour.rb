module Api
  module Dashboard
    module Office
      # returns a formatted version of the number of
      # orders by marketing type for the dashboard api
      class FormatTodayOrdersByHour
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.complete.not_cancelled
          @orders = valid_orders
          @range = nil
        end

        def run
          today_orders = Api::Dashboard::Office::FindTodayValidOrders.new(@orders).run
          grouped_orders = today_orders.group_by_hour(:completed_at, range: range).count
          grouped_orders.map do |k, v|
            { x: k.to_i, y: v }
          end
        end

        def range
          @range ||= Time.zone.now.at_beginning_of_day..Time.zone.now.beginning_of_hour - 1
        end
      end
    end
  end
end
