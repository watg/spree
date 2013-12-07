module Spree
  module Admin
    class GiftCardsController < Spree::Admin::BaseController
      def index
        @search = load_search
        @gift_cards = @search.result.includes([:buyer_order, :beneficiary_order]).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page]) 
      end

      private
      def load_search
        params[:q] ||= {}
        params[:q][:state_eq] = GiftCard::STATES.first if params[:q][:state].blank?
        GiftCard.accessible_by(current_ability, :index).ransack(params[:q])
      end
    end
  end
end
