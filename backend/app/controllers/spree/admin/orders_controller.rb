module Spree
  module Admin
    class OrdersController < Spree::Admin::BaseController
      before_action :initialize_order_events
      before_action :load_order, except: [:index, :new, :create]

      respond_to :html

      def index
        params[:q] ||= {}
        @search = ::Admin::Orders::Search.run!(params: params, current_ability: current_ability)
        @orders = ::Admin::Orders::OrdersBySearch.run!(params: params, search: @search)
      end

      def new
        @order = Order.new
        @order.created_by = try_spree_current_user
      end

      def create
        @order = Order.new
        @order.currency = params[:order][:currency] || Spree::Config[:default_currency]
        @order.order_type_id = params[:order][:order_type_id]
        @order.internal = params[:order][:internal]
        @order.created_by = try_spree_current_user
        @order.save!
        redirect_to cart_admin_order_url(@order)
      end

      def internal
        @order.internal= !@order.internal?
        @order.save(validation: false)
        redirect_to edit_admin_order_url(@order)
      end

      def important
        @order.toggle(:important)
        @order.save!
        redirect_to edit_admin_order_url(@order)
      end

      def refresh
        @order.update!
        redirect_to edit_admin_order_url(@order)
      end

      def gift_card_reissue
        Spree::GiftCardJobCreator.new(@order).run
        flash[:success] = "All gift cards will be re-issued for order #{@order.number}"
        redirect_to edit_admin_order_url(@order)
      end

      def edit
        can_not_transition_without_customer_info

        unless @order.completed?
          @order.refresh_shipment_rates
        end
      end
 
      def cart
        unless @order.completed?
          @order.refresh_shipment_rates
        end
        if @order.shipped_shipments.count > 0
          redirect_to edit_admin_order_url(@order)
        end
      end

      def show
        @order = Order.find_by_number!(params[:id])
        type = (params[:type] or :invoice).to_sym
        object = get_pdf(@order, type)
        if object.errors.any?
          flash[:error] = object.errors.to_sentence
          redirect_to :back
        else
          pdf = object.to_pdf
          respond_to do |format|
            format.pdf do
              send_data pdf, :filename => "#{type}.pdf",  :type => "application/pdf", disposition: :inline
            end
          end
        end
      end

      def update
        if @order.update_attributes(params[:order]) && @order.line_items.present?
          @order.update!
          unless @order.completed?
            # Jump to next step if order is not completed.
            redirect_to admin_order_customer_path(@order) and return
          end
        else
          @order.errors.add(:line_items, Spree.t('errors.messages.blank')) if @order.line_items.empty?
        end

        render :action => :edit
      end

      def cancel
        if @order.can_cancel?
          @order.canceled_by(try_spree_current_user)
          flash[:success] = Spree.t(:order_canceled)
        else
          flash[:notice] = "Order cannot be canceled"
        end
        redirect_to :back
      end

      def resume
        if @order.resume
          flash[:success] = Spree.t(:order_resumed)
        else
          flash[:error] =  @order.errors.full_messages.join(', ')
        end
        redirect_to :back
      end

      def approve
        @order.approved_by(try_spree_current_user)
        flash[:success] = Spree.t(:order_approved)
        redirect_to :back
      end

      def resend
        OrderMailer.confirm_email(@order.id, true).deliver
        flash[:success] = Spree.t(:order_email_resent)

        redirect_to :back
      end

      def open_adjustments
        adjustments = @order.all_adjustments.where(state: 'closed')
        adjustments.update_all(state: 'open')
        flash[:success] = Spree.t(:all_adjustments_opened)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      def close_adjustments
        adjustments = @order.all_adjustments.where(state: 'open')
        adjustments.update_all(state: 'closed')
        flash[:success] = Spree.t(:all_adjustments_closed)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      private

      def get_pdf(order, pdf_type)
        case pdf_type
        when :invoice
          Spree::PDF::CommercialInvoice.new(order)
        when :emergency_invoice
          Spree::PDF::EmergencyCommercialInvoice.new(order)
        when :packing_list
          Spree::PDF::PackingList.new(order)
        else
          Spree::PDF::ImageSticker.new(order)
        end
      end
      
      def order_params
        params[:created_by_id] = try_spree_current_user.try(:id)
        params.permit(:created_by_id)
      end

      def load_order
        # Spree auth calls load_order, hence you have no control over which actions
        # it is enabled for in the above before_filter like you may think...
        # hence only load the order if you have a params[:id] which is not the case
        # for a new
        unless params[:action] == 'create'
          @order = Order.includes(:adjustments).find_by_number!(params[:id])
          authorize! action, @order
        end
      end

        # Used for extensions which need to provide their own custom event links on the order details view.
        def initialize_order_events
          @order_events = %w{approve cancel resume}
        end

      def model_class
        Spree::Order
      end
    end
  end
end
