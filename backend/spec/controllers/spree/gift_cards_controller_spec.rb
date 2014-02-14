require 'spec_helper'

describe Spree::Admin::GiftCardsController, type: :controller do
  stub_admin_user

  it 'list all gift_cards' do
    spree_get :index
    expect(response).to be_success
  end

  context '#update' do
    let(:gift_card) { create(:gift_card) }

    Spree::GiftCard::STATES.each do |state|
      it "changes to valid state #{state}" do
        expect(Spree::UpdateGiftCardService).
          to receive(:run).
          with(gift_card_id: gift_card.id.to_s, attributes: {'state' =>  state}).
          and_return(OpenStruct.new(:success? => true))

        spree_put :update, {id: gift_card.id, gift_card: {state: state}}
      end
    end
    
    it 'changes to invalid state' do
      allow(Spree::UpdateGiftCardService).
        to receive(:run).
        and_return(OpenStruct.new(:success? => false))

      allow(subject).to receive(:reason)

      spree_put :update, {id: gift_card.id, gift_card: {state: 'wrong_state'}}

      expect(response).to_not be_success
    end
  end
end
