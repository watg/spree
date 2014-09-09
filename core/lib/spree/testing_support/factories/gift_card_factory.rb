FactoryGirl.define do
  factory :gift_card, class: Spree::GiftCard do
    buyer_order_line_item_position 0
    value 50

    before(:create) do |card|
      o = create(:order_with_line_items)
      card.buyer_order_line_item = o.line_items.first
      card.buyer_email = o.email
      card.buyer_order = o
      card.currency = o.currency
    end
  end
end
