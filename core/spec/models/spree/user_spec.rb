require 'spec_helper'

describe Spree::LegacyUser do
  subject { create(:user) }

  # Regression test for #2844 + #3346
  context "#last_incomplete_order" do
    let!(:user) { create(:user) }
    let!(:order) { create(:order, bill_address: create(:address), ship_address: create(:address)) }

    let!(:order_1) { create(:order, :created_at => 1.day.ago, :user => user, :created_by => user) }
    let!(:order_2) { create(:order, :user => user, :created_by => user) }
    let!(:order_3) { create(:order, :user => user, :created_by => create(:user)) }

    it "returns correct order" do
      user.last_incomplete_spree_order.should == order_2
    end

    context "persists order address" do
      it "copies over order addresses" do
        expect {
          user.persist_order_address(order)
        }.to change { Spree::Address.count }.by(2)

        expect(user.bill_address).to eq order.bill_address
        expect(user.ship_address).to eq order.ship_address
      end

      it "doesnt create new addresses if user has already" do
        user.update_column(:bill_address_id, create(:address))
        user.update_column(:ship_address_id, create(:address))
        user.reload

        expect {
          user.persist_order_address(order)
        }.not_to change { Spree::Address.count }
      end

      it "set both bill and ship address id on subject" do
        user.persist_order_address(order)

        expect(user.bill_address_id).not_to be_blank
        expect(user.ship_address_id).not_to be_blank
      end
    end
  end
  
  context "#find_or_create_unenrolled" do
    let(:tracking_cookie) { 'random-string' }
    it "creates a new user if enrolled with the same tracking cookie exists" do
      user = create(:user, email: 'someone@somewhere.com', enrolled: true, uuid: tracking_cookie)
      Spree::LegacyUser.find_or_create_unenrolled('someone_else@somewhere.com', tracking_cookie)
      expect(Spree::LegacyUser.find_by(email: 'someone@somewhere.com').enrolled).to eq true
      expect(Spree::LegacyUser.find_by(email: 'someone_else@somewhere.com').enrolled).to eq false
    end

    it "finds the existing user if an unenrolled one exists" do
      user = create(:user, email: 'someone@somewhere.com', enrolled: false)
      found_user = Spree::LegacyUser.find_or_create_unenrolled('someone@somewhere.com', tracking_cookie)
      expect(Spree::LegacyUser.find_by(email: 'someone@somewhere.com')).to eq found_user
    end
  end

  context "Class Methods" do
    let(:subject) { Spree.user_class }
    before do
      create(:user, email: 'bob@sponge.net', subscribed: true)
    end

    it "#customer_has_subscribed?" do
      expect(subject.customer_has_subscribed?('bob@sponge.net')).to be_true
    end
  end
  
end
