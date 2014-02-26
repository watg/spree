require 'spec_helper'

describe Spree::Promotion::Rules::ProductType do
  let(:rule) { Spree::Promotion::Rules::ProductType.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }

    it "should be eligible if there are no product_types" do
      rule.stub(:eligible_product_types => [])
      rule.should be_eligible(order)
    end

    before do
      @product1 = mock_model(Spree::Product, product_type: "kit")
      @product2 = mock_model(Spree::Product, product_type: "accessories")
    end

    context "with 'any' match policy" do
      it "should be eligible if any of the product types is in eligible product types" do
        order.stub(:products => [@product1, @product2])
        rule.stub(:eligible_product_types => ["accessories", "ready_to_wear"])
        rule.should be_eligible(order)
      end

      it "should not be eligible if none of the product types is in eligible product types" do
        order.stub(:products => [@product2])
        rule.stub(:eligible_product_types => ["kit", "ready_to_wear"])
        rule.should_not be_eligible(order)
      end
    end
  end
end