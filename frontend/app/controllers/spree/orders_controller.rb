module Spree
  class OrdersController < Spree::StoreController
    ssl_required :show

    before_action :check_authorization
    respond_to :js, :only => :populate

    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/products', 'spree/orders'

    respond_to :html

    before_action :assign_order_with_lock, only: :update
    before_action :apply_coupon_code, only: :update
    skip_before_action :verify_authenticity_token, only: [:populate]

    def index
      redirect_to root_path and return unless try_spree_current_user
      @orders = try_spree_current_user.orders.complete.order('completed_at desc')
    end

    def show
      @order = Order.find_by_number!(params[:id])
    end

    def update
      if @order.contents.update_cart(order_params)
        respond_with(@order) do |format|
          format.html do
            if params.has_key?(:checkout)
              @order.next if @order.cart?
              redirect_to checkout_state_path(@order.checkout_steps.first)
            else
              redirect_to cart_path
            end
          end
        end
      else
        respond_with(@order)
      end
    end

    # Shows the current incomplete order from the session
    def edit
      @order = current_order || Order.incomplete.find_or_initialize_by(guest_token: cookies.signed[:guest_token], currency: current_currency)

      # Remove any line_items which have been deleted
      @order.prune_line_items!
      associate_user
    end

    # Adds a new item to the order (creating a new order if none already exists)
    def populate
      populator = Spree::OrderPopulator.new(current_order(create_order_if_necessary: true), current_currency)
      populator.populate(params.slice(:products, :variants, :quantity, :parts, :target_id, :suite_id, :suite_tab_id))

      if populator.valid?
        @item = populator.item
        current_order.ensure_updated_shipments
        respond_with(@order) do |format|
          format.html { redirect_to cart_path }
        end
      else
        @errors = populator.errors.full_messages.join(" ")
        respond_with(@order) do |format|
          format.html do
            flash[:error] = @errors
            redirect_back_or_default(:back)
          end
        end
      end
    end

    def empty
      if @order = current_order
        @order.empty!
      end

      redirect_to spree.cart_path
    end

    def accurate_title
      if @order && @order.completed?
        Spree.t(:order_number, :number => @order.number)
      else
        Spree.t(:shopping_cart)
      end
    end

    def check_authorization
      cookies.permanent.signed[:guest_token] = params[:token] if params[:token]
      order = Spree::Order.find_by_number(params[:id]) || current_order

      if order
        authorize! :edit, order, cookies.signed[:guest_token]
      else
        authorize! :create, Spree::Order
      end
    end

    private

    def order_params
      if params[:order]
        params[:order].permit(*permitted_order_attributes)
      else
        {}
      end
    end

    def assign_order_with_lock
      @order = current_order(lock: true)
      unless @order
        flash[:error] = Spree.t(:order_not_found)
        redirect_to root_path and return
      end
    end
  end

end
