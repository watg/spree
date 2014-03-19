require 'spec_helper'

describe Spree::Promotion::Rules::Country do
  let(:rule) { Spree::Promotion::Rules::Country.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }

    it "should not be eligible if there are no countries" do
      rule.stub(:eligible_country_codes => [])
      rule.should be_eligible(order)
    end

    context "with 'any' match policy" do

      it "should be eligible if any of the countries is in the eligible countries" do
        order.stub(:last_ip_address => "1.2.3.4")
        rule.stub(:eligible_country_codes => ["UK", "US"])
        Geocoder.should_receive(:search).with("1.2.3.4").and_return([double("Geocode Country", :country_code => "US")])
        
        rule.should be_eligible(order)
      end

      it "should not be eligible if none of the countries is in the eligible countries" do
        order.stub(:last_ip_address => "5.6.7.8")
        rule.stub(:eligible_country_codes => ["US"])
        Geocoder.should_receive(:search).with("5.6.7.8").and_return([double("Geocode Country", :country_code => "UK")])

        rule.should_not be_eligible(order)
      end
    end
  end
end