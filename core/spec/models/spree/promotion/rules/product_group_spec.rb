require 'spec_helper'

describe Spree::Promotion::Rules::ProductGroup do
  let(:rule) { Spree::Promotion::Rules::ProductGroup.new }

  context "#eligible?(order)" do
    let(:order) { Spree::Order.new }

    it "should be eligible if there are no product_groups" do
      allow(rule).to receive_messages(:eligible_product_groups => [])
      expect(rule).to be_eligible(order)
    end

    before do
      3.times { |i| instance_variable_set("@product_group#{i}", mock_model(Spree::ProductGroup)) }
    end

    context "with 'any' match policy" do
      before { rule.preferred_match_policy = 'any' }

      it "should be eligible if any of the product groups is in eligible product_groups" do
        allow(order).to receive_messages(:product_groups => [@product_group1, @product_group2])
        allow(rule).to receive_messages(:eligible_product_groups => [@product_group2, @product_group3])
        expect(rule).to be_eligible(order)
      end

      it "should not be eligible if none of the product groups is in eligible product_groups" do
        allow(order).to receive_messages(:product_groups => [@product_group1])
        allow(rule).to receive_messages(:eligible_product_groups => [@product_group2, @product_group3])
        expect(rule).not_to be_eligible(order)
      end
    end

    context "with 'all' match policy" do
      before { rule.preferred_match_policy = 'all' }

      it "should be eligible if all of the eligible product groups are ordered" do
        allow(order).to receive_messages(:product_groups => [@product_group3, @product_group2, @product_group1])
        allow(rule).to receive_messages(:eligible_product_groups => [@product_group2, @product_group3])
        expect(rule).to be_eligible(order)
      end

      it "should not be eligible if any of the eligible product groups is not ordered" do
        allow(order).to receive_messages(:product_groups => [@product_group1, @product_group2])
        allow(rule).to receive_messages(:eligible_product_groups => [@product_group1, @product_group2, @product_group3])
        expect(rule).not_to be_eligible(order)
      end
    end
  end
end
