module Spree
  class GiftCardReport
    include BaseReport
    
    def initialize(params={})
      @from = params[:from].blank? ? Time.now.midnight : Time.parse(params[:from])  
      @to = params[:to].blank? ? Time.now.tomorrow.midnight : Time.parse(params[:to])  
    end
    
    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end
    
    def header
      %w(
buyer_order_date
buyer_order_number
buyer_order_email
state
value
currency
expiry_date
beneficiary_email
beneficiary_order
)
    end
    
    def retrieve_data
      Spree::GiftCard.find_each do |card|
        yield gift_card_data(card)
      end
    end
    
    def gift_card_data(card)
      [
       card.buyer_order.try(:created_at),
       card.buyer_order.try(:number),
       card.buyer_email,
       card.state,
       card.value,
       card.currency,
       card.expiry_date,
       card.beneficiary_email,
       card.beneficiary_order.try(:number)
      ]
    end
  end
end
