module Spree
  module Api
    class DashboardController < Spree::Api::BaseController
      def last_bought_product
        last_variant = Spree::Order.where('completed_at is not null').last.variants.last
        last_product = last_variant.product
        variant_image_url = last_variant.images.first.attachment.url if last_variant.images.any?
        response = { name: last_product.name, marketing_type: last_product.marketing_type.title, image_url: variant_image_url }

        respond_to do |format|
          format.json { render json: response.to_json }
        end
      end

      def today_sells
        today_sells = { EUR: 0, GBP: 0, USD: 0 }.merge(
          Spree::Order.where('completed_at >= ?', Time.zone.now.beginning_of_day).group('currency').sum(:total)
        )

        respond_to do |format|
          format.json { render json: today_sells.to_json }
        end
      end

      def today_orders
        today_orders = { total: Spree::Order.where('completed_at >= ?', Time.zone.now.beginning_of_day).count }

        respond_to do |format|
          format.json { render json: today_orders.to_json }
        end
      end

      def today_items
        today_items = Spree::LineItem.joins(:order).merge(Spree::Order.complete)
                      .where('spree_orders.completed_at > ?', Time.zone.now.beginning_of_day)
                      .sum(:quantity)

        respond_to do |format|
          format.json { render json: { total: today_items }.to_json }
        end
      end

      def today_sells_by_type
        sells_by_type = query_sells_by_type.sort_by(&:last).reverse!

        respond_to do |format|
          format.json { render json: sells_by_type.to_json }
        end
      end

      def today_orders_by_hour
        today_orders = Spree::Order.where('completed_at >= ?', Time.zone.now.beginning_of_day).group_by_hour(:completed_at, range: Date.today..Time.now).count.to_a

        today_orders.map! do |point|
          { x: point[0].to_i, y: point[1] }
        end

        respond_to do |format|
          format.json { render json: today_orders.to_json }
        end
      end

      private

      def query_sells_by_type
        data = Spree::LineItem.joins(:order).merge(Spree::Order.complete)
               .where('spree_orders.completed_at > ?', Time.zone.now.beginning_of_day)
               .joins(variant: [product: :marketing_type])
               .group('spree_marketing_types.title').sum(:quantity)
        data.sort.reverse!
      end
    end
  end
end
