module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of number of printed items by marketing type
        class FormatPrintedItemsByType
          def initialize(valid_orders)
            @printed_orders = valid_orders.where(shipment_state: "ready", payment_state: "paid")
          end

          def run
            StructureItemsByMarketingType.new(printed_orders_by_type).run
          end

          def printed_orders_by_type
            Spree::LineItem.joins(:order, variant: [product: :marketing_type])
              .select("spree_marketing_types.title as marketing_type_title,
                      spree_line_items.quantity as quantity")
              .merge(@printed_orders.where.not(invoice_print_job_id: nil))
          end
        end
      end
    end
  end
end
