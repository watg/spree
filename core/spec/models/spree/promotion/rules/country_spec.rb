require 'spec_helper'

describe Spree::Promotion::Rules::Country do
  let(:rule) { Spree::Promotion::Rules::Country.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }

    it "should not be eligible if there are no countries" do
      allow(rule).to receive_messages(:eligible_country_codes => [])
      expect(rule).to be_eligible(order)
    end

    context "with 'any' match policy" do

      it "should be eligible if any of the countries is in the eligible countries" do
        allow(order).to receive_messages(:last_ip_address => "1.2.3.4")
        allow(rule).to receive_messages(:eligible_country_codes => ["UK", "US"])
        expect(Geocoder).to receive(:search).with("1.2.3.4").and_return([double("Geocode Country", :country_code => "US")])
        
        expect(rule).to be_eligible(order)
      end

      it "should not be eligible if none of the countries is in the eligible countries" do
        allow(order).to receive_messages(:last_ip_address => "5.6.7.8")
        allow(rule).to receive_messages(:eligible_country_codes => ["US"])
        expect(Geocoder).to receive(:search).with("5.6.7.8").and_return([double("Geocode Country", :country_code => "UK")])

        expect(rule).not_to be_eligible(order)
      end
    end
  end
end