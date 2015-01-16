module Spree
  module Admin
    class StockTransfersController < Admin::BaseController
      before_action :load_stock_locations, only: :index

      def index
        @q = StockTransfer.ransack(params[:q])

        @stock_transfers = @q.result
                             .includes(:stock_movements => { :stock_item => :stock_location })
                             .order('created_at DESC')
                             .page(params[:page])
      end

      def show
        @stock_transfer = StockTransfer.find_by_param(params[:id])
      end

      def new
        @suppliers = Supplier.order(:firstname, :lastname)
      end


      def create
        outcome = Spree::StockTransferService::Create.run(params)

        if outcome.valid?
          flash[:success] = Spree.t(:stock_successfully_transferred)
          redirect_to admin_stock_transfer_path(outcome.result)
        else
          flash[:error] = outcome.errors.full_messages.to_sentence
          redirect_to new_admin_stock_transfer_path
        end
      
      end

      private
     

      def load_stock_locations
        @stock_locations = Spree::StockLocation.active.order_default
      end

    end
  end
end
