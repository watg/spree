require 'spec_helper'

describe Spree::Promotion::Rules::ItemTotal do
  let(:rule) { Spree::Promotion::Rules::ItemTotal.new }
  let(:united_kingdom) { create(:country, :name => "United Kingdom") }
  let(:ship_address) { create(:address, :country => united_kingdom, :first_name => "Rumpelstiltskin") }
  let(:bill_address) { create(:address, :country => united_kingdom, :first_name => "Rumpelstiltskin") }
  let(:order) { Spree::Order.create( :currency => 'GBP', :ship_address => ship_address, :bill_address => bill_address) }
  let(:order_currency_usd) { Spree::Order.create( :currency => 'USD', :ship_address => ship_address, :bill_address => bill_address) }
  let(:uk_zone) { create :zone , :name => 'UK'  }
  let(:other_zone) { create :zone , :name => 'OTHER'  }

  let(:another_country) { create(:country, :name => "Foobar") }
  let(:another_ship_address) { create(:address, :country => another_country, :first_name => "Rumpelstiltskin") }
  let(:another_order) { Spree::Order.create( :currency => 'GBP', :ship_address => another_ship_address, :bill_address => bill_address) }
  let(:order_no_address) { Spree::Order.create( :currency => 'GBP') }
  let(:preferred_attributes) { {
    uk_zone.id =>    { 'GBP' => { 'amount' =>'10', 'enabled' => 'true' },
                       'EUR' => { 'amount' =>'20', 'enabled' => 'true' },
                       'USD' => { 'amount' =>'20', 'enabled' => 'false'}, 
                     },
    other_zone.id => { 'GBP' => { 'amount' =>'10', 'enabled' => 'true' },
                     },
  } }

  before{ uk_zone.members.create(zoneable: united_kingdom) }
  before{ other_zone.members.create(zoneable: another_country) }
  before { rule.preferred_attributes = preferred_attributes  }

  context "uk zone" do

    it "should be eligible when zone-country is enabled - currency GBP" do
      allow(order).to receive_messages :line_items => [double(:line_item, :amount => 30, :currency => 'GBP'), double(:line_item, :amount => 21, :currency => 'GBP')]
      expect(rule).to be_eligible(order)
    end

    it "should be eligible when zone-country is enabled - currency EUR" do
      allow(order).to receive_messages :line_items => [double(:line_item, :amount => 10, :currency => 'EUR'), double(:line_item, :amount => 10, :currency => 'EUR')]
      allow(another_order).to receive_messages :currency => 'EUR' 
      expect(rule).to be_eligible(order)
    end

    it "should not be eligible when currency / zone is disabled" do
      allow(order_currency_usd).to receive_messages :line_items => [double(:line_item, :amount => 30, :currency => 'USD'), double(:line_item, :amount => 21, :currency => 'USD')]
      expect(rule).not_to be_eligible(order_currency_usd)
    end

    it "should not be eligible when amount is to small" do
      allow(order).to receive_messages :line_items => [double(:line_item, :amount => 5, :currency => 'GBP'), double(:line_item, :amount => 4, :currency => 'GBP')]
      expect(rule).not_to be_eligible(order)
    end

  end

  context "other zone" do

    it "should be eligible when zone-country is enabled - currency GBP" do
      allow(another_order).to receive_messages :line_items => [double(:line_item, :amount => 30, :currency => 'GBP'), double(:line_item, :amount => 21, :currency => 'GBP')]
      expect(rule).to be_eligible(another_order)
    end

    it "should not be eligible when zone-country does not exist - currency EUR" do
      allow(another_order).to receive_messages :line_items => [double(:line_item, :amount => 10, :currency => 'EUR'), double(:line_item, :amount => 10, :currency => 'EUR')]
      allow(another_order).to receive_messages :currency => 'EUR' 
      expect(rule).not_to be_eligible(another_order)
    end

    it "should not be eligible when amount is to small" do
      allow(another_order).to receive_messages :line_items => [double(:line_item, :amount => 5, :currency => 'GBP'), double(:line_item, :amount => 4, :currency => 'GBP')]
      expect(rule).not_to be_eligible(another_order)
    end

  end

  context "user has not entered their address" do

    it "should be eligible if the amounts are correct regardless of currency" do
      allow(order_no_address).to receive_messages :line_items => [double(:line_item, :amount => 30, :currency => 'GBP'), double(:line_item, :amount => 21, :currency => 'GBP')]
      expect(rule).to be_eligible(order_no_address)
    end

    it "should be eligible when zone-country does not exist - currency EUR" do
      allow(order_no_address).to receive_messages :line_items => [double(:line_item, :amount => 10, :currency => 'EUR'), double(:line_item, :amount => 10, :currency => 'EUR')]
      allow(order_no_address).to receive_messages :currency => 'EUR' 
      expect(rule).to be_eligible(order_no_address)
    end

    it "should not be eligible when amount is to small" do
      allow(order_no_address).to receive_messages :line_items => [double(:line_item, :amount => 5, :currency => 'GBP'), double(:line_item, :amount => 4, :currency => 'GBP')]
      allow(order_no_address).to receive_messages :currency => 'GBP' 
      expect(rule).not_to be_eligible(order_no_address)
    end

  end


end
