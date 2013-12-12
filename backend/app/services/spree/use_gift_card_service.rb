module Spree
  class UseGiftCardService < Mutations::Command
    required do
      duck :order
      string :code
    end

    def execute
      card = find_redeemable_card
      if card
        card.redeem!
        card.create_adjustment(adjustment_label(card), order, order, true)
        # TODO: so that we keep track of who used the card
        # if order is not (complete or paid) in 10m rerun 30m 
        # ::DelayedJob.enqueue UpdateGiftCardBeneficiaryJob.new(order, card), queue: 'gift_card', run_at: 10.minutes.from_now
        return success_message(card)
      else
        add_error(:card_not_found, :card_not_found, "Gift card not found!")
      end
      rescue Exception => e
      add_error(:could_not_apply, :could_not_apply, "Could not apply this gift card code")
    end

    private
    def find_redeemable_card
      card = Spree::GiftCard.where(state: 'not_redeemed',  code: code.upcase).first      
      return  if card.blank?
      if card.currency != order.currency
        add_error(:wrong_currency, :wrong_currency, "Your must have the same currency as your gift card!")
        return
      end 
      if card.expiry_date < Time.now
        add_error(:expired, :expired, "Your gift card has expired!")
        return
      end
      return card
    end

    def adjustment_label(card)
      "Gift Card #{card.value} #{card.currency}"
    end

    def success_message(card)
      "#{adjustment_label(card)} applied"
    end
  end
end
