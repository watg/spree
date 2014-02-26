require 'spec_helper'

describe Spree::UpdateGiftCardService do
  subject { Spree::UpdateGiftCardService }
  let(:gift_card) { create(:gift_card)}
  
  Spree::GiftCard::STATES.each do |state|
    it "update gift_card state" do
      outcome = subject.run(gift_card_id: gift_card.id, attributes: {state: state})
      expect(outcome).to be_success
      expect(outcome.result.state).to eql(state)
    end
  end
end
