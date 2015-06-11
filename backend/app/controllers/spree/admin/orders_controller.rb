module Spree
  module Admin
    # orders controller class
    class OrdersController < Spree::Admin::BaseController
      before_action :initialize_order_events
      before_action :load_order, except: [:index, :new, :create]
      before_action :prepare_show_order, only: [:show]
      respond_to :html

      def index
        params[:q] ||= {}
        @ransack = ::Admin::Orders::SearchService.run!(params: params,
                                                       current_ability: current_ability)
        @orders = ::Admin::Orders::OrdersBySearch.run!(params: params,
                                                       search: @ransack.search_object)
      end

      def new
        @order = Order.new
        @order.created_by = try_spree_current_user
      end

      def create
        @order = Order.new(create_order_params)
        @order.currency ||= Spree::Config[:default_currency]
        @order.save!
        redirect_to cart_admin_order_url(@order)
      end

      def internal
        @order.internal = !@order.internal?
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
        @order.refresh_shipment_rates unless @order.completed?
      end

      def cart
        @order.refresh_shipment_rates unless @order.completed?
        redirect_to edit_admin_order_url(@order) if @order.shipped_shipments.count > 0
      end

      def show
        outcome = ::Pdf::GenerateService.run(order: @order, type: order_type)
        if outcome.valid?
          respond_to { |format| format.pdf { generate_order_pdf(outcome.result)  }  }
        else
          flash[:error] = outcome.errors.full_messages.to_sentence
          redirect_to :back
        end
      end

      def update
        if persist_updates
          # Jump to next step if order is not completed.
          redirect_to(admin_order_customer_path(@order)) && return unless @order.completed?
        elsif @order.line_items.empty?
          @order.errors.add(:line_items, Spree.t("errors.messages.blank"))
        end

        render action: :edit
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
          flash[:error] = @order.errors.full_messages.join(", ")
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
        adjustments = @order.all_adjustments.where(state: "closed")
        adjustments.update_all(state: "open")
        flash[:success] = Spree.t(:all_adjustments_opened)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      def close_adjustments
        adjustments = @order.all_adjustments.where(state: "open")
        adjustments.update_all(state: "closed")
        flash[:success] = Spree.t(:all_adjustments_closed)

        respond_with(@order) { |format| format.html { redirect_to :back } }
      end

      private

      def create_order_params
        params.require(:order).permit(:currency, :order_type_id, :internal)
      end

      def persist_updates
        @order.update_attributes(params[:order]) && @order.line_items.present? && @order.update!
      end

      def order_params
        params[:created_by_id] = try_spree_current_user.try(:id)
        params.permit(:created_by_id)
      end

      def order_type
        (params[:type] || :invoice).to_sym
      end

      def prepare_show_order
        @order = Order.find_by_number!(params[:id])
      end

      def generate_order_pdf(order_object)
        send_data order_object.to_pdf,
                  filename: "#{order_type}.pdf",
                  type: "application/pdf",
                  disposition: :inline
      end

      def load_order
        # Spree auth calls load_order, hence you have no control over which actions
        # it is enabled for in the above before_filter like you may think...
        # hence only load the order if you have a params[:id] which is not the case
        # for a new
        return if params[:action] == "create"
        @order = Order.includes(:adjustments).find_by_number!(params[:id])
        authorize! action, @order
      end

      # Used for extensions which need to provide their
      # own custom event links on the order details view.
      def initialize_order_events
        @order_events = %w(approve cancel resume)
      end

      def model_class
        Spree::Order
      end
    end
  end
end
