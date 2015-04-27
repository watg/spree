module Spree
  module Api
    module Dashboard
      # Rest Interface for the office dashboard
      class OfficeController < Api::BaseController
        def last_bought_product
          response = ::Api::Dashboard::Office::FormatLastBoughtProduct.new.run
          render json: response.to_json
        end

        def today_sells
          today_sells = ::Api::Dashboard::Office::FormatTodaySells.new.run
          render json: today_sells.to_json
        end

        def today_orders
          today_orders = ::Api::Dashboard::Office::FormatTodayOrders.new.run
          render json: today_orders.to_json
        end

        def today_items
          today_items = ::Api::Dashboard::Office::FormatTodayItems.new.run
          render json: today_items.to_json
        end

        def today_sells_by_type
          sells_by_type = ::Api::Dashboard::Office::FormatTodaySellsByType.new.run
          render json: sells_by_type.to_json
        end

        def today_orders_by_hour
          today_orders = ::Api::Dashboard::Office::FormatTodayOrdersByHour.new.run
          render json: today_orders.to_json
        end
      end
    end
  end
end
