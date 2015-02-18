require 'spec_helper'

describe Spree::Promotion::Rules::MarketingType do
  let(:rule) { Spree::Promotion::Rules::MarketingType.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }
    let(:marketing_type_1) { create(:marketing_type, name: 'accessories') }
    let(:marketing_type_2) { create(:marketing_type, name: 'kit') }
    let(:marketing_type_3) { create(:marketing_type, name: 'ready_to_wear') }

    it "should be eligible if there are no marketing_types" do
      allow(rule).to receive_messages(:marketing_types => [])
      expect(rule).to be_eligible(order)
    end

    before do
      @product1 = mock_model(Spree::Product, marketing_type: marketing_type_1)
      @product2 = mock_model(Spree::Product, marketing_type: marketing_type_2)
    end

    context "with 'any' match policy" do
      it "should be eligible if any of the product types is in eligible product types" do
        allow(order).to receive_messages(:products => [@product1, @product2])
        allow(rule).to receive_messages(:marketing_types => [marketing_type_1, marketing_type_2])
        expect(rule).to be_eligible(order)
      end

      it "should not be eligible if none of the product types is in eligible product types" do
        allow(order).to receive_messages(:products => [@product2])
        allow(rule).to receive_messages(:marketing_types => [marketing_type_1, marketing_type_3])
        expect(rule).not_to be_eligible(order)
      end
    end
  end
end
