module Spree
  class CurrencyController < Spree::StoreController
    def set
      currency = supported_currencies.find { |c| c.iso_code == params[:currency] }
      session[:currency] = params[:currency] if Spree::Config[:allow_currency_change] || (try_spree_current_user && try_spree_current_user.has_spree_role?("admin"))
      respond_to do |format|
        format.json { render :json => !currency.nil? }
        format.html do
          redirect_to root_path
        end
      end
    end
  end
end
