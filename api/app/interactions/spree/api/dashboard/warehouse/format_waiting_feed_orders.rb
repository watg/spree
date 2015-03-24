module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of orders waiting feed divided in over 24h and under 24h
        class FormatWaitingFeedOrders
          def initialize(valid_orders)
            @orders = valid_orders
          end

          def run
            today_valid_orders = Spree::Api::Dashboard::Warehouse::FindTodayValidOrders
                                 .new(@orders).run
            wf_orders = {}
            wf_orders[:new] = today_valid_orders
                              .where(shipment_state: "awaiting_feed", payment_state: "paid")
                              .count

            wf_orders[:old] = @orders
                              .where(shipment_state: "awaiting_feed", payment_state: "paid")
                              .count - wf_orders[:new]
            wf_orders
          end
        end
      end
    end
  end
end
