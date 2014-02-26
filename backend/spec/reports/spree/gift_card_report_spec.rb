require 'spec_helper'

describe Spree::GiftCardReport do
  subject { Spree::GiftCardReport.new }
  let(:gift_card) { create(:gift_card) }
  it "retuns data for one card" do
    expect(subject.gift_card_data(gift_card)).
      to match_array([
                      gift_card.buyer_order.created_at,
                      gift_card.buyer_order.number,
                      gift_card.buyer_email,
                      gift_card.state,
                      gift_card.value,
                      gift_card.currency,
                      gift_card.expiry_date,
                      nil,
                      nil
                     ])
    
  end

  it "HEADERS" do
    expect(subject.header).to match_array(%w(buyer_order_date buyer_order_number buyer_order_email state value currency expiry_date beneficiary_email beneficiary_order ))
  end

end
