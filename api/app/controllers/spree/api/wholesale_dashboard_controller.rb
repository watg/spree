module Spree
  module Api
    # Rest Interface for the wholesale dashboard
    class WholesaleDashboardController < Spree::Api::BaseController
      def today_orders
        orders = { total: today_valid_orders.count }
        respond_to do |format|
          format.json { render json: orders.to_json }
        end
      end

      def today_order_shipped
        shipments = { total: Spree::Shipment.shipped
                             .joins(:order).merge(valid_orders)
                             .where('shipped_at > ?', Time.zone.now.at_beginning_of_day)
                             .count
        }
        respond_to do |format|
          format.json { render json: shipments.to_json }
        end
      end

      def printed_orders
        p_orders = {}
        p_orders[:new] = today_valid_orders
                         .where(shipment_state: 'ready', payment_state: 'paid').where.not(invoice_print_job_id: nil)
                         .count

        p_orders[:old] = valid_orders
                         .where(shipment_state: 'ready', payment_state: 'paid').where.not(invoice_print_job_id: nil)
                         .count - p_orders[:new]

        respond_to do |format|
          format.json { render json: p_orders.to_json }
        end
      end

      def printed_by_marketing_type
        p_orders = items_by_marketing_type(printed_items_by_type)
        respond_to do |format|
          format.json { render json: p_orders.to_json }
        end
      end

      def unprinted_orders
        unp_orders = {}
        unp_orders[:new] = today_valid_orders
                           .where(invoice_print_job_id: nil, shipment_state: 'ready', payment_state: 'paid')
                           .count

        unp_orders[:old] = valid_orders
                           .where(invoice_print_job_id: nil, shipment_state: 'ready', payment_state: 'paid')
                           .count - unp_orders[:new]

        respond_to do |format|
          format.json { render json: unp_orders.to_json }
        end
      end

      def unprinted_by_marketing_type
        unp_orders = items_by_marketing_type(unprinted_items_by_type)
        respond_to do |format|
          format.json { render json: unp_orders.to_json }
        end
      end

      def unprinted_orders_waiting_feed
        wf_orders = {}
        wf_orders[:new] = today_valid_orders
                          .where(shipment_state: 'awaiting_feed', payment_state: 'paid')
                          .count

        wf_orders[:old] = valid_orders
                          .where(shipment_state: 'awaiting_feed', payment_state: 'paid')
                          .count - wf_orders[:new]

        respond_to do |format|
          format.json { render json: wf_orders.to_json }
        end
      end

      def waiting_feed_by_marketing_type
        waiting_orders = items_by_marketing_type(waiting_feed_items_by_type)
        respond_to do |format|
          format.json { render json: waiting_orders.to_json }
        end
      end

      private

      def items_by_marketing_type(collection)
        orders = collection.group_by(&:marketing_type_title).map do |key, line_items|
          {
            key => line_items.map(&:quantity).reduce(:+)
          }
        end
        orders = Hash[*orders.collect(&:to_a).flatten]
        orders.sort_by { |hsh| - hsh.last } # orders the array by value in desc
      end

      def printed_items_by_type
        Spree::LineItem.joins(:order, variant: [product: :marketing_type])
          .select('spree_marketing_types.title as marketing_type_title, spree_line_items.quantity as quantity')
          .merge(valid_orders.where(shipment_state: 'ready', payment_state: 'paid')
                   .where.not(invoice_print_job_id: nil))
      end

      def unprinted_items_by_type
        Spree::LineItem.joins(:order, variant: [product: :marketing_type])
          .select('spree_marketing_types.title as marketing_type_title, spree_line_items.quantity as quantity')
          .merge(valid_orders.where(invoice_print_job_id: nil, shipment_state: 'ready', payment_state: 'paid'))
      end

      def waiting_feed_items_by_type
        Spree::LineItem.joins(:order, variant: [product: :marketing_type])
          .select('spree_marketing_types.title as marketing_type_title, spree_line_items.quantity as quantity')
          .merge(valid_orders.where(shipment_state: 'awaiting_feed', payment_state: 'paid'))
      end

      def today_valid_orders
        valid_orders.where('completed_at > ?', Time.zone.now.at_beginning_of_day)
      end

      def valid_orders
        Spree::Order.complete
      end
    end
  end
end
