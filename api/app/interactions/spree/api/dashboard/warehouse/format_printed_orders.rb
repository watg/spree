module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of printed orders divided in over 24h and under 24h
        class FormatPrintedOrders
          def initialize(valid_orders)
            @orders = valid_orders.not_cancelled
          end

          def run
            p_orders = {}
            today_valid_orders = Spree::Api::Dashboard::Warehouse::FindTodayValidOrders
                                 .new(@orders).run
            p_orders[:new] = today_valid_orders
                             .where(shipment_state: "ready", payment_state: "paid")
                             .where.not(invoice_print_job_id: nil).count
            p_orders[:old] = @orders
                             .where(shipment_state: "ready", payment_state: "paid")
                             .where.not(invoice_print_job_id: nil).count - p_orders[:new]
            p_orders
          end
        end
      end
    end
  end
end
