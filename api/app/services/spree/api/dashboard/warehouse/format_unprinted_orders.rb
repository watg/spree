module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of unprinted orders divided in over 24h and under 24h
        class FormatUnprintedOrders
          def initialize(valid_orders = nil)
            valid_orders ||= Spree::Order.all
            @unprinted_orders = valid_orders
                                .shippable_state.where(shipment_state: "ready",
                                                       internal: false,
                                                       batch_invoice_print_date: nil,
                                                       payment_state: "paid")
            @today_unprinted_orders = Spree::Api::Dashboard::Warehouse::FindTodayValidOrders
                                      .new(@unprinted_orders).run
          end

          def run
            unp_orders = {}
            unp_orders[:new] = new_unprinted_orders
            unp_orders[:old] = old_unprinted_orders
            unp_orders
          end

          def new_unprinted_orders
            @today_unprinted_orders.count
          end

          def old_unprinted_orders
            @unprinted_orders.count - new_unprinted_orders
          end
        end
      end
    end
  end
end
