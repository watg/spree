module Spree
  module Api
    module Dashboard
      # Rest Interface for the wholesale dashboard
      class WarehouseController < Spree::Api::BaseController
        def today_orders
          today_orders = Spree::Api::Dashboard::Warehouse::FormatTodayOrders.new.run
          render json: today_orders.to_json
        end

        def today_sells_by_marketing_type
          today_orders = Spree::Api::Dashboard::Warehouse::FormatTodaySellsByType.new.run
          render json: today_orders.to_json
        end

        def today_shipments
          today_shipments = Spree::Api::Dashboard::Warehouse::FormatTodayShipments.new.run
          render json: today_shipments.to_json
        end

        def printed_orders
          p_orders = Spree::Api::Dashboard::Warehouse::FormatPrintedOrders.new.run
          render json: p_orders.to_json
        end

        def printed_by_marketing_type
          p_orders = Spree::Api::Dashboard::Warehouse::FormatPrintedItemsByType.new.run
          render json: p_orders.to_json
        end

        def unprinted_orders
          unp_orders = Spree::Api::Dashboard::Warehouse::FormatUnprintedOrders.new.run
          render json: unp_orders.to_json
        end

        def unprinted_by_marketing_type
          unp_orders = Spree::Api::Dashboard::Warehouse::FormatUnprintedItemsByType.new.run
          render json: unp_orders.to_json
        end

        def unprinted_orders_waiting_feed
          wf_orders = Spree::Api::Dashboard::Warehouse::FormatWaitingFeedOrders.new.run
          render json: wf_orders.to_json
        end

        def waiting_feed_by_marketing_type
          wf_orders = Spree::Api::Dashboard::Warehouse::FormatWaitingFeedByType.new.run
          render json: wf_orders.to_json
        end

        def today_shipments_by_country
          shipments = Spree::Api::Dashboard::Warehouse::FormatTodayShipmentsByCountry.new.run
          render json: shipments.to_json
        end
      end
    end
  end
end
