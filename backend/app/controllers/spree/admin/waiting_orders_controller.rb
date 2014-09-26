module Spree
  module Admin

    class WaitingOrdersController < Spree::Admin::BaseController

      def index
        @all_boxes = Spree::Parcel.find_boxes
        @batch_size = Spree::BulkOrderPrintingService::BATCH_SIZE
        @unprinted_invoice_count = Spree::Order.unprinted_invoices.count
        @unprinted_image_count = Spree::Order.unprinted_image_stickers.count

        @orders = Spree::Order.to_be_packed_and_shipped
        # @search needs to be defined as this is passed to search_form_for

        params[:q] ||= {}
        @search = @orders.ransack(params[:q])
        @collection = @search.result(distinct: true)

        # subtract all orders, which are in the excluded select box
        @collection = @collection - @orders.where("spree_products.marketing_type_id IN (?)", params[:ignored_marketing_type_ids])
        @collection = Kaminari.paginate_array(@collection).page(params[:page]).per(15)
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
        unprinted_orders = Spree::Order.unprinted_invoices

        # apply the ransack and exclude filters
        orders = unprinted_orders.ransack(params[:q]).result(distinct: true)
        orders = orders - unprinted_orders.where("spree_products.marketing_type_id IN (?)", params[:ignored_marketing_type_ids])

        outcome = Spree::BulkOrderPrintingService.new.print_invoices(orders)
        handle_pdf(outcome, "invoices.pdf")
      end

      def image_stickers
        orders = Spree::Order.unprinted_image_stickers
        outcome = Spree::BulkOrderPrintingService.new.print_image_stickers(orders)
        handle_pdf(outcome, "image_stickers.pdf")
      end

      def create_and_allocate_consignment
        outcome = Spree::CreateAndAllocateConsignmentService.run(order_id: params[:id])
        handle_pdf(outcome, 'label.pdf')
      end

      private

      def pdf_type
        params[:pdf_type]
      end

      def handle_pdf(outcome, filename)
        if outcome.valid?
          send_data outcome.result, disposition: :inline, filename: filename, type: "application/pdf"
        else
          flash[:error] = outcome.errors.full_messages.to_sentence
          redirect_to admin_waiting_orders_url(params: params.slice(:q, :ignored_marketing_type_ids))
        end
      end

      def handle(outcome)
        if outcome.valid?
          respond_to do |format|
            format.html {
              redirect_to admin_waiting_orders_url(params: params.slice(:q, :ignored_marketing_type_ids))
            }
            format.json { render :json => {success: true}.to_json}
          end
        else
          respond_to do |format|
            format.html {
              flash[:error] = outcome.errors.full_messages.to_sentence
              redirect_to admin_waiting_orders_url(params: params.slice(:q, :ignored_marketing_type_ids))
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

    end

  end
end
