module Spree
  class IssueGiftCardService < Mutations::Command

    required do
      duck :order
      duck :line_item
      integer :position
    end

    def execute
      return unless valid_gift_card_variant?
      issuance_email(create_gift_card)
    end
    
    private
    def valid_gift_card_variant?
      if line_item.variant.product.product_type != 'gift_card'
        add_error(:line_item, :invalid, "Product on line item is not a GIFT CARD!")
        return false
      end
      true
    end

    def create_gift_card
      Spree::GiftCard.find_or_create_by!(buyer_order_line_item_position: position,
                              buyer_order_line_item_id: line_item.id,
                              buyer_email: order.email,
                              buyer_order: order,
                              currency:    order.currency,
                              value:       value)
      rescue
      add_error(:gift_card, :invalid, "Could not create gift card for order: #{order.number}, line item: #{line_item.id}, postion: #{position} --- GIFT CARD SKU: #{line_item.variant.sku}")
    end

    def issuance_email(gift_card)
      Spree::GiftCardMailer.issuance_email(gift_card).deliver
      rescue
      if gift_card
        add_error(:issuance_email, :not_delivered, "Could not send email for gift card id: #{gift_card.id}")
      end
    end

    def value
      line_item.variant.current_price_in(order.currency).price.to_f
    end
  end
end
