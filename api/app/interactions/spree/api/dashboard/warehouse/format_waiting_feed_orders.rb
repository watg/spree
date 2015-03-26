module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of orders waiting feed divided in over 24h and under 24h
        class FormatWaitingFeedOrders
          def initialize(valid_orders = Spree::Order.all)
            @wf_orders = valid_orders
                         .shippable_state
                         .where(shipment_state: "awaiting_feed",
                                internal: false,
                                payment_state: "paid",
                                batch_invoice_print_date: nil)
            @today_wf_orders = Spree::Api::Dashboard::Warehouse::FindTodayValidOrders
                               .new(@wf_orders).run
          end

          def run
            wf_orders = {}
            wf_orders[:new] = new_waiting_feed_orders

            wf_orders[:old] = old_waiting_feed_orders
            wf_orders
          end

          def new_waiting_feed_orders
            @today_wf_orders.count
          end

          def old_waiting_feed_orders
            @wf_orders.count - new_waiting_feed_orders
          end
        end
      end
    end
  end
end
