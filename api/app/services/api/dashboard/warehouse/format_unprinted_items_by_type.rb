module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of number of unprinted items by marketing type
      class FormatUnprintedItemsByType
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.all
          @unprinted_items = retrieve_unprinted_items(valid_orders)
        end

        def run
          StructureItemsByMarketingType.new(@unprinted_items).run
        end

        private

        def retrieve_unprinted_items(valid_orders)
          Spree::LineItem
            .joins(:order, variant: [product: :marketing_type])
            .select("spree_marketing_types.title as marketing_type_title,
                                      spree_line_items.quantity as quantity")
            .merge(valid_orders.shippable_state
                 .where(shipment_state: "ready",
                        internal: false,
                        batch_invoice_print_date: nil,
                        payment_state: "paid"))
        end
      end
    end
  end
end