module Spree
  class IssueGiftCardService < Mutations::Command

    required do
      duck :line_item
      duck :order
    end

    def execute
      return false unless valid_gift_card_variant?
      line_item.quantity.times {|n| issue_one_gift_card(n) }
    end
    
    private
    def issue_one_gift_card(position)
      gift_card = Spree::GiftCard.create!(buyer_order_line_item_position: position,
                                          buyer_order_line_item_id: line_item.id,
                                          buyer_email: order.email,
                                          buyer_order: order,
                                          currency:    order.currency,
                                          value:       value)
      Spree::GiftCardMailer.issuance_email(gift_card).deliver
    end
    
    def valid_gift_card_variant?
      line_item.variant.product.product_type == 'gift_card'
    end

    def value
      line_item.variant.current_price_in(order.currency).price.to_f
    end
  end
end
