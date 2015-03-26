module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of number of waiting feed items by marketing type
        class FormatWaitingFeedByType
          def initialize(valid_orders = Spree::Order.all)
            @wf_items = Spree::LineItem
                        .joins(:order, variant: [product: :marketing_type])
                        .select("spree_marketing_types.title as marketing_type_title,
                                        spree_line_items.quantity as quantity")
                        .merge(valid_orders.shippable_state
                                .where(shipment_state: "awaiting_feed",
                                       internal: false,
                                       batch_invoice_print_date: nil,
                                       payment_state: "paid"))
          end

          def run
            StructureItemsByMarketingType.new(@wf_items).run
          end
        end
      end
    end
  end
end
