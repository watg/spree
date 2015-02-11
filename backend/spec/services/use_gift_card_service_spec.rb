require 'spec_helper'

describe Spree::UseGiftCardService do
  subject { Spree::UseGiftCardService }
  let(:gift_card) { create(:gift_card) }
  let(:order) { gift_card.buyer_order }

  it "allows customer to use gift card" do
    outcome = subject.run(order: order, code: gift_card.code)
    expect(outcome.valid?).to be_true
    expect(order.reload.adjustments.gift_card.first.source).to eq(gift_card)
  end

# Disabled due to customer care calls
#  it "adds future job after updating order" do
#    mock_job = double('job')
#
#    expect(Spree::GiftCardOrderTTLJob).to receive(:new)
#    subject.run(order: order, code: gift_card.code)
#  end

  context "validation" do
    let(:order_in_eur) { create(:order, currency: 'EUR') }
    it "checks that order and gift card currency are the same" do
      outcome = subject.run(order: order_in_eur, code: gift_card.code)
      expect(outcome.errors.keys).to include(:wrong_currency)
    end

    it "checks expiry_date" do
      allow(gift_card).to receive(:expiry_date) { 1.day.ago }
      outcome = subject.run(order: order_in_eur, code: gift_card.code)
      expect(outcome.errors.keys).to include(:wrong_currency)
    end
  end
end
