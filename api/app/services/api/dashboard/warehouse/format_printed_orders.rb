module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of printed orders divided in over 24h and under 24h
      class FormatPrintedOrders
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.all
          @printed_orders = valid_orders
                            .shippable_state
                            .where(shipment_state: "ready",
                                   internal: false,
                                   payment_state: "paid")
                            .where.not(batch_invoice_print_date: nil)
          @today_printed_orders = Api::Dashboard::Warehouse::FindTodayValidOrders
                                  .new(@printed_orders).run
        end

        def run
          p_orders = {}
          p_orders[:new] = new_printed_orders
          p_orders[:old] = old_printed_orders
          p_orders
        end

        def new_printed_orders
          @today_printed_orders.count
        end

        def old_printed_orders
          @printed_orders.count - new_printed_orders
        end
      end
    end
  end
end