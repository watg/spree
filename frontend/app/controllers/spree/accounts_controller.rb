class Spree::AccountsController < Spree::StoreController
  ssl_required
  skip_before_filter :set_current_order, :only => :show
  prepend_before_filter :load_object, :only => [:show, :edit, :update]
  prepend_before_filter :authorize_actions, :only => :new

  include Spree::Core::ControllerHelpers

  def show
    if @user.referrer_profile.present?    
      outcome = Spree::Raf::CalculateApprovedRewardsService.run(
        user: @user,
        currency: @user.referrer_profile.currency)

      @redeemable_rewards = outcome.result[:redeemable_rewards]
      @redeemed_all_rewards = outcome.result[:redeemed_all_rewards]
      @pending_rewards = outcome.result[:pending_rewards]
    else
      @no_profile = true
    end
  end

  private

  def load_object
    @user ||= try_spree_current_user
    unless @user
      store_location
      redirect_to login_path
      return
    end
    authorize! params[:action].to_sym, @user
  end

end