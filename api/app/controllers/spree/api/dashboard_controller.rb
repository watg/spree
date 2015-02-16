module Spree
  module Api
    class DashboardController < Spree::Api::BaseController
      def last_bought_product
        last_product=Spree::Order.last.products.last
        response={name: last_product.name, marketing_type: last_product.marketing_type.title}
        respond_to do |format|
          format.json { render :json => response.to_json }
        end
      end

      def today_sells
        today_sells={EUR: 0, GBP: 0, USD: 0}.merge(
          Spree::Order.where("created_at >= ?", Time.zone.now.beginning_of_week).group('currency').sum(:total)
        )
        respond_to do |format|
          format.json { render :json => today_sells.to_json }
        end
      end

      def today_orders
        today_orders={ total: Spree::Order.where("created_at >= ?", Time.zone.now.beginning_of_day).count }
        respond_to do |format|
          format.json { render :json => today_orders.to_json }
        end
      end
#todo
      def today_orders_by_type
        last_product=Spree::LineItem.where("spree_line_items.created_at >= ?", Time.zone.now.beginning_of_month).
          joins(:product).
          joins('RIGHT JOIN spree_marketing_types ON spree_marketing_types.id=spree_products.marketing_type_id').
          group('spree_marketing_types.title').count

          respond_to do |format|
          format.json { render :json => last_product.to_json }
        end
      end
    end
  end
end
