module Spree
  module Admin
    class StockMovementsController < Spree::Admin::BaseController
      respond_to :html
      helper_method :stock_location

      def index
        @stock_movements = stock_location.stock_movements.recent.page(params[:page])
      end

      def new
        @stock_movement = stock_location.stock_movements.build
      end

      def create
        if params[:stock_movement][:stock_location_id].present?
          variant = Variant.find(params[:stock_item].delete(:variant_id))
          location = StockLocation.find(params[:stock_movement].delete(:stock_location_id))
          @stock_movement = location.stock_movements.build(params[:stock_movement])
          @stock_movement.stock_item = location.stock_items.where(variant_id: variant).first_or_create
          @stock_movement.save ? flash[:success] = flash_message_for(@stock_movement, :successfully_created) : flash[:error] = Spree.t(:could_not_create_stock_movement)
          redirect_to :back
        else
          @stock_movement = stock_location.stock_movements.build(params[:stock_movement])
          @stock_movement.save
          flash[:success] = flash_message_for(@stock_movement, :successfully_created)
          redirect_to admin_stock_location_stock_movements_path(stock_location)
        end
      end

      def edit
        @stock_movement = StockMovement.find(params[:id])
      end

      private

      def stock_location
        @stock_location ||= StockLocation.find(params[:stock_location_id])
      end
    end
  end
end

