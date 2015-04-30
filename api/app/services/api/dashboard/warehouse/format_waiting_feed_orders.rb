module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of orders waiting feed divided in over 24h and under 24h
      class FormatWaitingFeedOrders
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.all
          @waiting_feed_orders = valid_orders
                                 .shippable_state
                                 .where(shipment_state: "awaiting_feed",
                                        internal: false,
                                        payment_state: "paid",
                                        batch_invoice_print_date: nil)
          @today_waiting_feed_orders = Api::Dashboard::Warehouse::FindTodayValidOrders
                                       .new(@waiting_feed_orders).run
        end

        def run
          wf_orders = {}
          wf_orders[:new] = new_waiting_feed_orders

          wf_orders[:old] = old_waiting_feed_orders
          wf_orders
        end

        def new_waiting_feed_orders
          @today_waiting_feed_orders.count
        end

        def old_waiting_feed_orders
          @waiting_feed_orders.count - new_waiting_feed_orders
        end
      end
    end
  end
end
