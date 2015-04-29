module Admin
  module WaitingOrders
    class Search < ActiveInteraction::Base
      hash :params,
           strip: false
      interface :current_ability

      def execute
        params[:q][:filter_express] ||= '1'
        params[:q][:express] = params[:q][:filter_express] == "1"

        @orders = Spree::Order.to_be_packed_and_shipped
        @search = @orders.ransack(params[:q])
      end

    end
  end
end
