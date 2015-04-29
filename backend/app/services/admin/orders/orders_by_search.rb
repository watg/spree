module Admin
  module Orders
    class OrdersBySearch < ActiveInteraction::Base
      hash :params,
           strip: false
      interface :search

      def execute
        # lazyoading other models here (via includes) may result in an invalid query
        # e.g. SELECT  DISTINCT DISTINCT "spree_orders".id, "spree_orders"."created_at" AS alias_0 FROM "spree_orders"
        # see https://github.com/spree/spree/pull/3919
        @orders = search_results
      end

      private

      def search_results
        search.result(distinct: true).
        page(params[:page]).
        per(params[:per_page] || Spree::Config[:orders_per_page])
      end
    end
  end
end
