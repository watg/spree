module Spree
  module Admin
    class OrdersController < Spree::Admin::BaseController
      before_action :initialize_order_events
      before_action :load_order, only: [:edit, :update, :cancel, :resume, :approve, :resend, :open_adjustments, :close_adjustments, :cart, :important]

      respond_to :html

      def index
        params[:q] ||= {}
        params[:q][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
        @show_only_completed = params[:q][:completed_at_not_null] == '1'
        params[:q][:s] ||= @show_only_completed ? 'completed_at desc' : 'created_at desc'

        # As date params are deleted if @show_only_completed, store
        # the original date so we can restore them into the params
        # after the search
        created_at_gt = params[:q][:created_at_gt]
        created_at_lt = params[:q][:created_at_lt]

        params[:q].delete(:inventory_units_shipment_id_null) if params[:q][:inventory_units_shipment_id_null] == "0"

        if params[:q][:created_at_gt].present?
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue ""
        end

        if params[:q][:created_at_lt].present?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if @show_only_completed
          params[:q][:completed_at_gt] = params[:q].delete(:created_at_gt)
          params[:q][:completed_at_lt] = params[:q].delete(:created_at_lt)
        end

        @search = Order.accessible_by(current_ability, :index).ransack(params[:q])

        # lazyoading other models here (via includes) may result in an invalid query
        # e.g. SELECT  DISTINCT DISTINCT "spree_orders".id, "spree_orders"."created_at" AS alias_0 FROM "spree_orders"
        # see https://github.com/spree/spree/pull/3919
        @orders = @search.result(distinct: true).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page])

        # Restore dates
        params[:q][:created_at_gt] = created_at_gt
        params[:q][:created_at_lt] = created_at_lt
      end

      def new
        @order = Order.new
        @order.created_by = try_spree_current_user
      end

      def create
        @order = Order.new
        @order.currency = params[:order][:currency] || Spree::Config[:default_currency]
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
        @order.deliver_gift_card_emails
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
