require  File.join(Rails.root,'vendor/spree/core/app/jobs/spree/gift_card_order_ttl_job.rb')
module Spree
  class UseGiftCardService < ActiveInteraction::Base

    string  :code
    model :order, class: 'Spree::Order'

    def execute
      card = find_redeemable_card
      if card
        card.redeem!
        card.create_adjustment(adjustment_label(card), order, order, true)
        ::Delayed::Job.enqueue Spree::GiftCardOrderTTLJob.new(order, card), queue: 'gift_card', run_at: 2.hours.from_now
        return success_message(card)
      end
      card
    rescue Exception => e
      errors.add(:could_not_apply, "Could not apply this gift card code")
      nil
    end

    private
    def find_redeemable_card
      card = Spree::GiftCard.where(state: 'not_redeemed',  code: code.upcase).first
      if card.blank?
        errors.add(:card_not_found, "Gift card not found!")
        return
      end
      if card.currency != order.currency
        errors.add(:wrong_currency, "Ensure your purchase is in the currency your gift card is applicable for (#{card.currency})")
        return
      end
      if card.expiry_date < Time.now
        errors.add(:expired, "Your gift card has expired!")
        return
      end
      card
    end

    def adjustment_label(card)
      "Gift Card #{card.value} #{card.currency}"
    end

    def success_message(card)
      [
       "#{adjustment_label(card)} applied.",
       "Your gift card was successfully registered.",
       "Happy days! And don't forget to thank someone."
      ][ rand(3) ]
    end
  end
end
