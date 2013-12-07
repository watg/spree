module Spree
  class UpdateGiftCardService < Mutations::Command

    required do
      integer :gift_card_id
      duck :attributes
    end
    
    def execute
      card = Spree::GiftCard.find(gift_card_id)
      card.state = attributes[:state] unless attributes[:state].blank?
      if card.valid?
        card.save
      else
        errors = card.errors
      end
      card
    end
  end
end
