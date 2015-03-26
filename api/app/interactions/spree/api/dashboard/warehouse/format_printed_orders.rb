module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of printed orders divided in over 24h and under 24h
        class FormatPrintedOrders
          def initialize(valid_orders = Spree::Order.all)
            @p_orders = valid_orders
                        .shippable_state
                        .where(shipment_state: "ready",
                               internal: false,
                               payment_state: "paid")
                        .where.not(batch_invoice_print_date: nil)
            @today_p_orders = Spree::Api::Dashboard::Warehouse::FindTodayValidOrders
                              .new(@p_orders).run
          end

          def run
            p_orders = {}
            p_orders[:new] = new_printed_orders
            p_orders[:old] = old_printed_orders
            p_orders
          end

          def new_printed_orders
            @today_p_orders.count
          end

          def old_printed_orders
            @p_orders.count - new_printed_orders
          end
        end
      end
    end
  end
end
