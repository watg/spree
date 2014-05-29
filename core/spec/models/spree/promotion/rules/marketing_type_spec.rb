require 'spec_helper'

describe Spree::Promotion::Rules::MarketingType do
  let(:rule) { Spree::Promotion::Rules::MarketingType.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }
    let(:marketing_type_1) { create(:marketing_type, name: 'accessories') }
    let(:marketing_type_2) { create(:marketing_type, name: 'kit') }
    let(:marketing_type_3) { create(:marketing_type, name: 'ready_to_wear') }

    it "should be eligible if there are no marketing_types" do
      rule.stub(:marketing_types => [])
      rule.should be_eligible(order)
    end

    before do
      @product1 = mock_model(Spree::Product, marketing_type: marketing_type_1)
      @product2 = mock_model(Spree::Product, marketing_type: marketing_type_2)
    end

    context "with 'any' match policy" do
      it "should be eligible if any of the product types is in eligible product types" do
        order.stub(:products => [@product1, @product2])
        rule.stub(:marketing_types => [marketing_type_1, marketing_type_2])
        rule.should be_eligible(order)
      end

      it "should not be eligible if none of the product types is in eligible product types" do
        order.stub(:products => [@product2])
        rule.stub(:marketing_types => [marketing_type_1, marketing_type_3])
        rule.should_not be_eligible(order)
      end
    end
  end
end
