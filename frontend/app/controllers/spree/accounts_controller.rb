class Spree::AccountsController < Spree::StoreController
  ssl_required
  skip_before_filter :set_current_order, :only => :show
  prepend_before_filter :load_object, :only => [:show, :edit, :update]
  prepend_before_filter :authorize_actions, :only => :new

  include Spree::Core::ControllerHelpers

  def show
    if @user.referrer_profile.present?
      total = @user.referrer_profile.rewards.redeemed.sum(:amount)
      @redeemed_amount = Spree::Money.new(total, { currency: @user.referrer_profile.currency }).to_html(no_cents: true)
    else
      @no_profile = true
    end
  end

  private

    def load_object
      @user ||= try_spree_current_user
      redirect_to root_path and return unless @user
      authorize! params[:action].to_sym, @user
    end

end