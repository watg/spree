module Spree
  module Api
    module Dashboard
      # Rest Interface for the office dashboard
      class OfficeController < Spree::Api::BaseController
        def last_bought_product
          response = Spree::Api::Dashboard::Office::FormatLastBoughtProduct
                     .new(Spree::Order.complete).run
          render json: response.to_json
        end

        def today_sells
          today_sells = Spree::Api::Dashboard::Office::FormatTodaySells
                        .new(Spree::Order.complete).run
          render json: today_sells.to_json
        end

        def today_orders
          today_orders = Spree::Api::Dashboard::Office::FormatTodayOrders
                         .new(Spree::Order.complete).run
          render json: today_orders.to_json
        end

        def today_items
          today_items = Spree::Api::Dashboard::Office::FormatTodayItems
                        .new(Spree::Order.complete).run
          render json: today_items.to_json
        end

        def today_sells_by_type
          sells_by_type = Spree::Api::Dashboard::Office::FormatTodaySellsByType
                          .new(Spree::Order.complete).run
          render json: sells_by_type.to_json
        end

        def today_orders_by_hour
          today_orders = Spree::Api::Dashboard::Office::FormatTodayOrdersByHour
                         .new(Spree::Order.complete).run
          render json: today_orders.to_json
        end
      end
    end
  end
end
