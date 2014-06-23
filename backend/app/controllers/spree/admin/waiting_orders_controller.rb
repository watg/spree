module Spree
  module Admin

    class WaitingOrdersController < Spree::Admin::BaseController
      def index
        @all_boxes = Spree::Parcel.find_boxes
        @batch_size = Spree::BulkOrderPrintingService::BATCH_SIZE
        @unprinted_invoice_count = Spree::Order.unprinted_invoices.count
        @unprinted_image_count = Spree::Order.unprinted_image_stickers.count
        if params[:batch_id].present?
          @orders = Spree::Order.where(batch_print_id: params[:batch_id])
        else
          @curr_page, @per_page = pagination_helper(params)
          @orders = load_orders_waiting.order('batch_print_id DESC').page(@curr_page).per(@per_page)
        end
      end

      def update
        outcome = Spree::AddParcelToOrderService.run(parcel_params)
        handle(outcome)
      end

      def destroy
        outcome = Spree::RemoveParcelToOrderService.run(parcel_params)
        handle(outcome)
      end

      def invoices
        outcome = Spree::BulkOrderPrintingService.run(pdf: :invoices)
        handle_pdf(outcome, "invoices.pdf")
      end

      def image_stickers
        outcome = Spree::BulkOrderPrintingService.run(pdf: :image_stickers)
        handle_pdf(outcome, "image_stickers.pdf")
      end

      def create_and_allocate_consignment
        outcome = Spree::CreateAndAllocateConsignmentService.run(order_id: params[:id])
        handle_pdf(outcome, 'label.pdf')
      end

      private
      def load_orders_waiting
        Spree::Order.to_be_packed_and_shipped
      end

      def pdf_type
        params[:pdf_type]
      end

      def handle_pdf(outcome, filename)
        if outcome.success?
          send_data outcome.result, disposition: :inline, filename: filename, type: "application/pdf"
        else
          flash[:error] = outcome.errors.message_list.join('<br/ >')
          redirect_to admin_waiting_orders_url
        end
      end

      def handle(outcome)
        if outcome.success?
          respond_to do |format|
            format.html {
              redirect_to admin_waiting_orders_url(page: params[:page], batch_id: params[:batch_id])
            }
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
