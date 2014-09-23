module Spree
  module Admin

    class WaitingOrdersController < Spree::Admin::BaseController

      def index
        @all_boxes = Spree::Parcel.find_boxes
        @batch_size = Spree::BulkOrderPrintingService::BATCH_SIZE
        @unprinted_invoice_count = Spree::Order.unprinted_invoices.count
        @unprinted_image_count = Spree::Order.unprinted_image_stickers.count

        # return @collection if @collection.present?

        params[:q] ||= {}
        params[:q] = JSON.parse(params[:q]) if params[:q].kind_of? String

        @collection = Spree::Order.to_be_packed_and_shipped
        # @search needs to be defined as this is passed to search_form_for
        @search = @collection.ransack(params[:q])
        @collection = @search.result.
          page(params[:page]).
          per( 15 )
        @collection
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
        if outcome.valid?
          send_data outcome.result, disposition: :inline, filename: filename, type: "application/pdf"
        else
          flash[:error] = outcome.errors.full_messages.to_sentence
          redirect_to admin_waiting_orders_url
        end
      end

      def handle(outcome)
        if outcome.valid?
          respond_to do |format|
            format.html {
              redirect_to admin_waiting_orders_url(q: params[:q])
            }
            format.json { render :json => {success: true}.to_json}
          end
        else
          respond_to do |format|
            format.html {
              flash[:error] = outcome.errors.full_messages.to_sentence
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
