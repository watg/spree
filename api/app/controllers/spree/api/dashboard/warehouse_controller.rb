module Spree
  module Api
    module Dashboard
      # Rest Interface for the wholesale dashboard
      class WarehouseController < Api::BaseController
        def today_orders_by_priority
          today_orders = ::Api::Dashboard::Warehouse::FormatTodayOrdersByPriority.new.run
          render json: today_orders.to_json
        end

        def today_sells_by_marketing_type
          today_orders = ::Api::Dashboard::Warehouse::FormatTodaySellsByType.new.run
          render json: today_orders.to_json
        end

        def today_shipments_by_priority
          today_shipments = ::Api::Dashboard::Warehouse::FormatTodayShipmentsByPriority.new.run
          render json: today_shipments.to_json
        end

        def printed_orders
          p_orders = ::Api::Dashboard::Warehouse::FormatPrintedOrders.new.run
          render json: p_orders.to_json
        end

        def printed_by_marketing_type
          p_orders = ::Api::Dashboard::Warehouse::FormatPrintedItemsByType.new.run
          render json: p_orders.to_json
        end

        def unprinted_orders
          unp_orders = ::Api::Dashboard::Warehouse::FormatUnprintedOrders.new.run
          render json: unp_orders.to_json
        end

        def unprinted_by_marketing_type
          unp_orders = ::Api::Dashboard::Warehouse::FormatUnprintedItemsByType.new.run
          render json: unp_orders.to_json
        end

        def unprinted_orders_waiting_feed
          wf_orders = ::Api::Dashboard::Warehouse::FormatWaitingFeedOrders.new.run
          render json: wf_orders.to_json
        end

        def waiting_feed_by_marketing_type
          wf_orders = ::Api::Dashboard::Warehouse::FormatWaitingFeedByType.new.run
          render json: wf_orders.to_json
        end

        def today_shipments_by_country
          shipments = ::Api::Dashboard::Warehouse::FormatTodayShipmentsByCountry.new.run
          render json: shipments.to_json
        end
      end
    end
  end
end
