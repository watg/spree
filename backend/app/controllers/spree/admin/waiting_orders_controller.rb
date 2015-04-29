module Spree
  module Admin

    class WaitingOrdersController < Spree::Admin::BaseController

      def index
        @all_boxes = Spree::Parcel.find_boxes
        @batch_size = Spree::BulkOrderPrintingService::BATCH_SIZE
        params[:q] ||= {}
        @search = ::Admin::WaitingOrders::Search.run!(params: params, current_ability: current_ability)
        @collection = @search.result(distinct: true)
        # subtract all orders, which are in the excluded select box
        @collection = @collection.where("spree_products.marketing_type_id NOT IN (?)", params.fetch(:ignored_marketing_type_ids,"-1"))
        @unprinted_invoice_count = @collection.unprinted_invoices.size
        @unprinted_image_count = @collection.unprinted_image_stickers.size
        @unprinted_invoice_total = Spree::Order.unprinted_invoices.size
        @unprinted_image_total = Spree::Order.unprinted_image_stickers.size
        @collection = @collection.page(params[:page]).per(15)
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
        params[:q] ||= {}
        params[:q][:express] = params[:q][:filter_express] == "1"
        # apply the ransack and exclude filters
        orders = unprinted_orders.ransack(params[:q]).result(distinct: true)
        orders = orders - unprinted_orders.where("spree_products.marketing_type_id IN (?)", params[:ignored_marketing_type_ids])

        outcome = Spree::BulkOrderPrintingService.new.print_invoices(orders)
        handle_pdf(outcome, "invoices.pdf")
      end

      def image_stickers
        unprinted_image_stickers = Spree::Order.unprinted_image_stickers
        params[:q] ||= {}
        params[:q][:express] = params[:q][:filter_express] == "1"
        # apply the ransack and exclude filters
        orders = unprinted_image_stickers.ransack(params[:q]).result(distinct: true)
        orders = orders - unprinted_image_stickers.where("spree_products.marketing_type_id IN (?)", params[:ignored_marketing_type_ids])

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
