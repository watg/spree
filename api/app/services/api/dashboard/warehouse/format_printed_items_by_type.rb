module Api
  module Dashboard
    module Warehouse
      # returns a formatted version of number of printed items by marketing type
      class FormatPrintedItemsByType
        def initialize(valid_orders = Spree::Order.all)
          @p_items = Spree::LineItem
                     .joins(:order, variant: [product: :marketing_type])
                     .select("spree_marketing_types.title as marketing_type_title,
                                      spree_line_items.quantity as quantity")
                     .merge(valid_orders.shippable_state
                            .where(shipment_state: "ready",
                                   internal: false,
                                   payment_state: "paid")
                            .where.not(batch_invoice_print_date: nil))
        end

        def run
          StructureItemsByMarketingType.new(@p_items).run
        end
      end
    end
  end
end