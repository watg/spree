module Spree
  module Admin
    module GiftCardsHelper
      def state_confirm_message
        {
          'paused'      => 'Put this gift card on hold?',
          'not_redeemed' => 'Reactivate this gift card?',
          'refunded'     => 'Refund this gift card?'
        }
      end
      
      def title_text
        {
          'paused' => 'Pause',
          'refunded' => 'Refund',
          'not_redeemed' => 'Activate'
        }
      end

      def states_allowed
        ['paused', 'not_redeemed', 'refunded']
      end
    end
  end
end
