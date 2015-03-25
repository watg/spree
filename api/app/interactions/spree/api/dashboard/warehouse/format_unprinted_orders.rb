module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of unprinted orders divided in over 24h and under 24h
        class FormatUnprintedOrders
          def initialize(valid_orders = Spree::Order.complete.not_cancelled)
            @orders = valid_orders
            @today_orders = Spree::Api::Dashboard::Warehouse::FindTodayValidOrders.new(@orders).run
          end

          def run
            unp_orders = {}
            unp_orders[:new] = new_unprinted_orders
            unp_orders[:old] = old_unprinted_orders
            unp_orders
          end

          def new_unprinted_orders
            @today_orders.where(invoice_print_job_id: nil,
                                shipment_state: "ready",
                                payment_state: "paid").count
          end

          def old_unprinted_orders
            @orders.where(invoice_print_job_id: nil,
                          shipment_state: "ready",
                          payment_state: "paid").count - new_unprinted_orders
          end
        end
      end
    end
  end
end
