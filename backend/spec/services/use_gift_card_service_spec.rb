require 'spec_helper'

describe Spree::UseGiftCardService do
  subject { Spree::UseGiftCardService }
  let(:order) { create(:order, currency: 'GBP') }
  let(:gift_card) { create(:gift_card, currency: 'GBP') }
	
pending('THE WHOLE OF GIFT CARD HAS TO BE REVIEWED CLOSELY -- ')

  xit "allows customer to use gift card" do
    outcome = subject.run(order: order, code: gift_card.code)
    expect(outcome).to be_success
    expect(order.reload.adjustments.gift_card.first.originator).to eq(gift_card)
  end

  xit "adds future job after updating order" do
    mock_job = double('job')
    
    expect(Spree::GiftCardOrderTTLJob).to receive(:new)
    subject.run(order: order, code: gift_card.code)    
  end

  context "validation" do
    let(:order_in_usd) { build(:order, currency: 'USD') }
    xit "checks that order and gift card currency are the same" do
      outcome = subject.run(order: order_in_usd, code: gift_card.code)
      expect(outcome.errors.keys).to include('wrong_currency')
    end

    xit "checks expiry_date" do
      allow(gift_card).to receive(:expiry_date) { 1.day.ago }
      outcome = subject.run(order: order_in_usd, code: gift_card.code)
      expect(outcome.errors.keys).to include('wrong_currency')
    end
  end
end
