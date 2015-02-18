require 'spec_helper'

describe Spree::GiftCard do
  subject { create(:gift_card) }

  context "class methods" do
    subject { Spree::GiftCard }
    it "matches code of gift card format" do
      expect(subject.match_gift_card_format?('D1C7-D614B8-511C')).to be true
    end
    it "doesn't matches other codes" do
      expect(subject.match_gift_card_format?('RACHELRUTT10')).to be false
    end
  end

  context 'fields populated at creation' do
    describe '#buyer_order' do
      subject { super().buyer_order }
      it { is_expected.not_to be_blank }
    end

    describe '#code' do
      subject { super().code }
      it { is_expected.to match(/\w{4}\-\w{6}\-\w{4}/) }
    end

    describe '#expiry_date' do
      subject { super().expiry_date }
      it { is_expected.not_to be_blank }
    end

    describe '#state' do
      subject { super().state }
      it { is_expected.to eq('not_redeemed')}
    end
  end

  it "has defined states" do
    expect(Spree::GiftCard::STATES).to match_array(['not_redeemed',
                                                    'redeemed',
                                                    'paused',
                                                    'cancelled',
                                                    'refunded'])
  end

  context "#eligible?" do
    let(:order) { create(:order) }
    it "checks expiry_date" do
      card = build(:gift_card, expiry_date: 1.day.ago)
      expect(card.eligible?(order)).to be false
    end

    it "checks beneficiary order has not changed  when state is redeemed" do
      second_order = create(:order)
      card = build(:gift_card, expiry_date: 1.day.from_now, beneficiary_order: order, beneficiary_email: order.email, state: 'redeemed')
      expect(card.eligible?(second_order)).to be false
    end

    %w(cancelled refunded paused).each do |state|
      it "checks state is not #{state}" do
        card = build(:gift_card, expiry_date: 1.day.from_now, beneficiary_order: nil, beneficiary_email: nil, state: state)
        expect(card.eligible?(order)).to be false
      end
    end

    it "returns true for state redeemed and same order" do
      card = build(:gift_card, expiry_date: 1.day.from_now, beneficiary_order: order, beneficiary_email: order.email, state: 'redeemed')
      expect(card.eligible?(order)).to be true
    end

    it "also returns true not_redeemed not order" do
      card = build(:gift_card, expiry_date: 1.day.from_now, beneficiary_order: nil, beneficiary_email: nil, state: 'not_redeemed')
      expect(card.eligible?(order)).to be true
    end
  end

  context 'states' do
    Spree::GiftCard::STATES.each do |state|
      it "allows #{state} " do
        subject.state = state
        expect(subject).to be_valid
      end
    end

    it "does allow anything else" do
      subject.state = 'bad_state'
      expect(subject).to be_invalid
    end

    context 'changes' do
      it 'tells if can change to desired state from not_redeemed' do
        card = build(:gift_card, state: 'not_redeemed')

        expect(card.change_state_to?('redeemed')).to be true
        expect(card.change_state_to?('paused')).to be true
        expect(card.change_state_to?('cancelled')).to be true
        expect(card.change_state_to?('refunded')).to be true
      end

      it 'tells if can change to desired state from redeemed' do
        card = build(:gift_card, state: 'redeemed')

        expect(card.change_state_to?('not_redeemed')).to be false
        expect(card.change_state_to?('paused')).to be false
        expect(card.change_state_to?('cancelled')).to be false
        expect(card.change_state_to?('refunded')).to be true
      end

      it 'tells if can change to desired state from paused' do
        card = build(:gift_card, state: 'paused')

        expect(card.change_state_to?('not_redeemed')).to be true
        expect(card.change_state_to?('redeemed')).to be false
        expect(card.change_state_to?('cancelled')).to be true
        expect(card.change_state_to?('refunded')).to be true
      end

      it 'tells if can change to desired state from cancelled' do
        card = build(:gift_card, state: 'cancelled')

        expect(card.change_state_to?('not_redeemed')).to be false
        expect(card.change_state_to?('redeemed')).to be false
        expect(card.change_state_to?('paused')).to be false
        expect(card.change_state_to?('refunded')).to be false
      end

      it 'tells if can change to desired state from refunded' do
        card = build(:gift_card, state: 'refunded')

        expect(card.change_state_to?('not_redeemed')).to be false
        expect(card.change_state_to?('redeemed')).to be false
        expect(card.change_state_to?('paused')).to be false
        expect(card.change_state_to?('cancelled')).to be false
      end

    end
  end
end
