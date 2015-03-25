module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of number of unprinted items by marketing type
        class FormatUnprintedItemsByType
          def initialize(valid_orders = Spree::Order.complete.not_cancelled)
            @unprinted_orders = valid_orders.where(invoice_print_job_id: nil,
                                                   shipment_state: "ready",
                                                   payment_state: "paid")
          end

          def run
            StructureItemsByMarketingType.new(unprinted_orders_by_type).run
          end

          def unprinted_orders_by_type
            Spree::LineItem.joins(:order, variant: [product: :marketing_type])
              .select("spree_marketing_types.title as marketing_type_title,
                      spree_line_items.quantity as quantity")
              .merge(@unprinted_orders)
          end
        end
      end
    end
  end
end
