module Spree
  module Admin
    module Orders
      class HoldsController < Spree::Admin::BaseController
        def new
          @order = find_order
        end

        def create
          @order = find_order
          hold = Spree::HoldService.run(
            order:  @order,
            reason: params[:reason],
            user:   try_spree_current_user,
            type:   params[:type],
          )

          if hold.valid?
            flash[:success] = "Order #{@order.number} put on hold"
            redirect_to([:edit, :admin, @order])
          else
            flash.now[:error] = "Failed to put order #{@order.number} put on hold"
            render :new
          end
        end

        def show
          @order = find_order
          @note = find_note(@order)
        end

        def destroy
          order = find_order
          order.remove_hold!
          flash[:success] = "Order #{order.number} no longer on hold"
          redirect_to([:edit, :admin, order])
        end

        private

        def find_order
          Spree::Order.find_by_number(params[:order_id])
        end

        def find_note(order)
          order.order_notes.find(params[:id])
        end
      end
    end
  end
end
