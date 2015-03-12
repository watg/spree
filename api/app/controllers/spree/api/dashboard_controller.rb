module Spree
  module Api
    # Rest Interface for the dashboard
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
        today_sells = today_valid_orders.group_by(&:currency).inject(EUR: 0, GBP: 0, USD: 0) do |h, (currency, orders)|
          h[currency] = orders.map(&:total).reduce(:+)
          h
        end
        respond_to do |format|
          format.json { render json: today_sells.to_json }
        end
      end

      def today_orders
        today_orders = { total: today_valid_orders.count }

        respond_to do |format|
          format.json { render json: today_orders.to_json }
        end
      end

      def today_items
        today_items = Spree::LineItem.joins(:order).merge(today_valid_orders).to_a.map(&:quantity).reduce(:+)
        respond_to do |format|
          format.json { render json: { total: today_items }.to_json }
        end
      end

      def today_sells_by_type
        sells_by_type = query_sells_by_type.to_a

        respond_to do |format|
          format.json { render json: sells_by_type.to_json }
        end
      end

      def today_orders_by_hour
        today_orders = today_valid_orders.group_by_hour(:completed_at, range: Date.today..Time.zone.now.beginning_of_hour - 1).count.to_a

        today_orders.map! do |point|
          { x: point[0].to_i, y: point[1] }
        end

        respond_to do |format|
          format.json { render json: today_orders.to_json }
        end
      end

      private

      def query_sells_by_type
        # todo improve this query
        data = Spree::LineItem.joins(:order).merge(today_valid_orders).group_by { |ri| ri.variant.product.marketing_type.title }.map do |key, line_items|
          {
            key => line_items.map(&:quantity).reduce(:+)
          }
        end
        data.sort_by { |_name, value| value }
        Hash[*data.collect(&:to_a).flatten].sort.reverse
      end

      def today_valid_orders
        Spree::Order.complete.where('completed_at > ?', Time.zone.now.at_beginning_of_day).where.not(
          email: 'request@woolandthegang.com').where(internal: false).joins(payments: :payment_method).merge(
          Spree::PaymentMethod.where(name: ['Credit Card', 'PayPal'])).uniq
      end
    end
  end
end
