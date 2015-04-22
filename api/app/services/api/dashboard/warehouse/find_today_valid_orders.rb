module Api
  module Dashboard
    module Warehouse
      # Filters valid orders returning only the new ones.
      class FindTodayValidOrders
        def initialize(validated_orders)
          @orders = validated_orders
        end

        def run
          @orders.where("completed_at > ?", Time.zone.now.at_beginning_of_day)
        end
      end
    end
  end
end