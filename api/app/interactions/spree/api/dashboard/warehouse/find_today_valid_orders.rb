module Spree
  module Api
    module Dashboard
      module Warehouse
        # Find valid orders completed today.
        class FindTodayValidOrders
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            @orders.where("completed_at > ?", Time.zone.now.at_beginning_of_day)
          end
        end
      end
    end
  end
end
