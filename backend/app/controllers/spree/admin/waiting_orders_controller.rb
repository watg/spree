module Spree
  module Admin

    class WaitingOrdersController < Spree::Admin::BaseController
      def index
        @curr_page, @per_page = pagination_helper(params)
        @all_boxes = Spree::Parcel.find_boxes
        @orders = Spree::Order.where(state: :complete).page(@curr_page).per(@per_page)
      end

      def update
        outcome = Spree::AddParcelToOrderService.run(parcel_params)
        if outcome.success?
          respond_to do |format|
            format.html { redirect_to admin_waiting_orders_url(page: params[:page]) }
            format.json { render :json => {success: true}.to_json}
          end
        else
          respond_to do |format|
            format.html { render :index }
            format.json { render :json => {success: false}.to_json}
          end
        end
      end

      def destroy
        raise "define me"
      end

      def batch
        raise "define me"
      end

      private
      def parcel_params
        {
          order_id:  params[:id],
          box_id:    params[:box][:id],
          quantity:  params[:box][:quantity]
        }
      end
      
      def pagination_helper( params )
        per_page = params[:per_page].to_i
        per_page = per_page > 0 ? per_page : Spree::Config[:orders_per_page]
        page = (params[:page].to_i <= 0) ? 1 : params[:page].to_i 
        curr_page = page || 1
        [curr_page, per_page]
      end
      
    end

  end
end
