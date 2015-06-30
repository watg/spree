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

    def populate
      order = current_order(create_order_if_necessary: true)
      outcome = ::Orders::PopulateService.run(order: order, params: params)

      if outcome.valid?
        @item = outcome.result
        respond_with(@order) do |format|
          format.js { render :layout => false }
          format.html { redirect_to cart_path }
        end
      else
        errors = outcome.errors.full_messages.join(" ")
        Rails.logger.error("Populator Error: #{errors}")
        Helpers::AirbrakeNotifier.notify("Populate Errors", errors)
        respond_with(@order) do |format|
          format.js { render :layout => false }
          flash[:error] = 'something went wrong, please try again'
          format.html do
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
