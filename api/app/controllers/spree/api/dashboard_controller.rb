module Spree
  module Api
    class DashboardController < Spree::Api::BaseController
      def last_bought_product
        last_product=Spree::Order.last.products.last
        response={name: last_product.name, marketing_type: last_product.marketing_type.title ,image_url: last_product.images.first.direct_upload_url}
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

      def today_sells_by_type
        sells_by_type=query_sells_by_type

        respond_to do |format|
          format.json { render :json => sells_by_type.to_json }
        end
      end

      private

      def query_sells_by_type
        ActiveRecord::Base.connection.exec_query("SELECT COUNT(product_id) AS total, spree_marketing_types.title AS title
        FROM \"spree_line_items\"
        INNER JOIN \"spree_variants\" ON \"spree_variants\".\"id\" = \"spree_line_items\".\"variant_id\" AND (spree_line_items.created_at >= '#{Time.zone.now.beginning_of_day}') AND \"spree_variants\".\"deleted_at\" IS NULL
        INNER JOIN \"spree_products\" ON \"spree_products\".\"id\" = \"spree_variants\".\"product_id\" AND \"spree_products\".\"deleted_at\" IS NULL
        RIGHT JOIN spree_marketing_types ON spree_marketing_types.id=spree_products.marketing_type_id
        WHERE title IS NOT NULL
        GROUP BY spree_marketing_types.title")
      end
    end
  end
end
