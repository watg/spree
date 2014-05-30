require 'spec_helper'

describe Spree::IssueGiftCardService do
  subject { Spree::IssueGiftCardService }
  let(:item_with_gift_card) { create(:line_item, quantity: 1, variant: create(:product, product_type: create(:product_type_gift_card)).master) }
  let(:order) { item_with_gift_card.order }
  let(:item)  { create(:line_item, quantity: 1, variant: create(:product).master, order: order) }
  let(:gift_card) { create(:gift_card, buyer_order_line_item_id: item_with_gift_card.id, 
                           buyer_email: order.email,
                           buyer_order: order,
                           currency: order.currency,
                           value: item_with_gift_card.variant.price.to_f) }
  
  it "skips processsing when line_item does have gift card" do
    outcome = subject.run(order: order, line_item: item, position: 0)
    expect(outcome.success?).to be_false
    expect(outcome.errors.message_list).to eq(['Product on line item is not a GIFT CARD!'])
  end

  context "issuing card" do
    before do
      allow(Spree::GiftCard).
        to receive(:create!).
        with(
             buyer_order_line_item_position: 0,
             buyer_order_line_item_id: item_with_gift_card.id, 
             buyer_email: order.email,
             buyer_order: order,
             currency:    order.currency,
             value:       item_with_gift_card.variant.price.to_f
             ).
        and_return(gift_card)
    end

    it "creates gift card" do
      expect(Spree::GiftCard).
        to receive(:create!).
        with(
             buyer_order_line_item_position: 0,
             buyer_order_line_item_id: item_with_gift_card.id, 
             buyer_email: order.email,
             buyer_order: order,
             currency:    order.currency,
             value:       item_with_gift_card.variant.price.to_f
             ).
        and_return(gift_card)

      subject.run(order: order, line_item: item_with_gift_card, position: 0)
    end
    
   it "sends email with gift card" do
      expect(Spree::GiftCardMailer).
        to receive(:issuance_email).
        with(gift_card).
        and_return(double('mailer', deliver: true))

      subject.run(order: order, line_item: item_with_gift_card, position: 0)
    end
  end
end
