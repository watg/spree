module Spree
  module Admin

    class WaitingOrdersController < Spree::Admin::BaseController
      def index
        @curr_page, @per_page = pagination_helper(params)
        @all_boxes = Spree::Parcel.find_boxes
        @orders = load_orders_waiting.page(@curr_page).per(@per_page)
      end

      def update
        outcome = Spree::AddParcelToOrderService.run(parcel_params)
        handle(outcome)
      end

      def destroy
        outcome = Spree::RemoveParcelToOrderService.run(parcel_params)
        handle(outcome)
      end

      def batch
        outcome = Spree::BulkOrderPrintingService.run
        respond_to do |format|
          format.pdf do
            send_data outcome.result, disposition: :inline, filename: 'invoices.pdf', type: "application/pdf"
          end
        end
      end

      def create_and_allocate_consignment
        outcome = Spree::CreateAndAllocateConsignmentService.run(order_id: params[:id])
        if outcome.success?
          send_data outcome.result, disposition: :inline, filename: "label.pdf", type: "application/pdf"
        else
          handle(outcome)
        end
      end

      private
      def load_orders_waiting
        Spree::Order.to_be_packed_and_shipped
      end

      def handle(outcome)
        if outcome.success?
          respond_to do |format|
            format.html { redirect_to admin_waiting_orders_url(page: params[:page]) }
            format.json { render :json => {success: true}.to_json}
          end
        else
          respond_to do |format|
            format.html {
              flash[:error] = outcome.errors.message_list.join('<br/ >')
              redirect_to admin_waiting_orders_url
            }
            format.json { render :json => {success: false}.to_json}
          end
        end
      end

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
