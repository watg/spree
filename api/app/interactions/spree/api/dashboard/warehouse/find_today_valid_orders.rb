module Spree
  module Api
    module Dashboard
      module Warehouse
        # Filters valid orders returning only the new ones.
        class FindTodayValidOrders
          def initialize(valid_orders)
            @orders = valid_orders.not_cancelled
          end

          def run
            @orders.where("completed_at > ?", Time.zone.now.at_beginning_of_day)
          end
        end
      end
    end
  end
end
