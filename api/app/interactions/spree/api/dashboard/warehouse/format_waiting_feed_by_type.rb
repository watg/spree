module Spree
  module Api
    module Dashboard
      module Warehouse
        # returns a formatted version of number of waiting feed items by marketing type
        class FormatWaitingFeedByType
          def initialize(valid_orders)
            @waiting_feed_orders = valid_orders.where(shipment_state: "awaiting_feed",
                                                      payment_state: "paid")
          end

          def run
            StructureItemsByMarketingType.new(waiting_feed_orders_by_type).run
          end

          def waiting_feed_orders_by_type
            Spree::LineItem.joins(:order, variant: [product: :marketing_type])
              .select("spree_marketing_types.title as marketing_type_title,
                      spree_line_items.quantity as quantity")
              .merge(@waiting_feed_orders)
          end
        end
      end
    end
  end
end
