module Spree
  module Admin
    class GiftCardsController < Spree::Admin::BaseController
      def index
        @search = load_search
        @gift_cards = @search.result.includes([:buyer_order, :beneficiary_order]).
          page(params[:page]).
          per(params[:per_page] || Spree::Config[:orders_per_page]) 
      end

      def update
        outcome = Spree::UpdateGiftCardService.run(gift_card_id: params[:id], attributes: params[:gift_card])
        answer = {message: 'ok'}
        status = 200
        unless outcome.success?
          status = 400
          answer = {
            message: 'error',
            reason: reason(outcome)
          }
        end
        render json: answer, status: status
      end

      private
      def load_search
        params[:q] ||= {}
        GiftCard.accessible_by(current_ability, :index).ransack(params[:q])
      end

      def reason(outcome)
        outcome.errors.message_list.join(', ')
      end
    end
  end
end
