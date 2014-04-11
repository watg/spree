require 'spec_helper'

describe Spree::GiftCardOrderTTLJob do
  let(:order)     { create(:order) }
  let(:gift_card) { create(:gift_card, state: 'redeemed', beneficiary_order: order, beneficiary_email: order.email) }
  subject { Spree::GiftCardOrderTTLJob.new(order, gift_card) }
  pending "--------------- THE WHOLE OF GIFT CARD HAS TO BE REVIEWED -----------"
  before do
    gift_card.create_adjustment('label', order, order, true)
  end

  xit 'resets gift card' do
    subject.perform

    gift_card.reload
    expect(gift_card.state).to eq('not_redeemed')
    expect(gift_card.beneficiary_email).to be_nil
    expect(gift_card.beneficiary_order).to be_nil
  end
  
  xit "lock order adjustment for that gift card" do
    subject.perform
    
    order.reload
    expect(order.adjustments.gift_card.first).to_not be_blank
    expect(order.adjustments.gift_card.first.state).to eql('finalized')
  end
end
