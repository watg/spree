require 'spec_helper'

describe Spree::GiftCardOrderTTLJob do
  let(:order)     { create(:order) }
  let(:gift_card) { create(:gift_card, state: 'redeemed', beneficiary_order: order, beneficiary_email: order.email) }
  subject { Spree::GiftCardOrderTTLJob.new(order, gift_card) }

  before do
    allow(gift_card).to receive(:compute_amount).with(order).and_return 10
    gift_card.create_adjustment('label', order, order, true)
  end

  it 'resets gift card' do
    subject.perform

    gift_card.reload
    expect(gift_card.state).to eq('not_redeemed')
    expect(gift_card.beneficiary_email).to be_nil
    expect(gift_card.beneficiary_order).to be_nil
  end

  it "locks order adjustment for that gift card" do
    adjustment = order.adjustments.gift_card.first
    expect(adjustment.amount).to eq 10

    subject.perform
    expect(adjustment.reload).to be_present
    expect(adjustment.amount).to eq 0
    expect(adjustment.amount).to eq 0
    expect(adjustment.state).to eql('closed')

    adjustment.update_column(:amount, 20)
    expect(adjustment.reload.amount).to eq 20

    subject.perform
    expect(adjustment.reload.amount).to eq 0
    expect(adjustment.state).to eq 'closed'
  end
end
