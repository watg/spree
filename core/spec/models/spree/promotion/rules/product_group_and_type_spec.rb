require 'spec_helper'

describe Spree::Promotion::Rules::ProductGroupAndType do
  let(:rule) { Spree::Promotion::Rules::ProductGroupAndType.new }

  context "#eligible?(order)" do
    let(:line_item) { create(:line_item) }
    let(:product) { line_item.product }
    let(:order) { line_item.order }
    let(:product_group_1) { create(:product_group) }
    let(:product_group_2) { create(:product_group) }
    let(:marketing_type_1) { create(:marketing_type, name: 'accessories') }
    let(:marketing_type_2) { create(:marketing_type, name: 'kit') }


    before do
      product.marketing_type = marketing_type_1
      product.product_group = product_group_1 
      product.save
    end


    it "should be eligible if there is no criteria" do
      allow(rule).to receive_messages(:eligible_product_groups => [])
      allow(rule).to receive_messages(:eligible_marketing_types => [])
      expect(rule).to be_eligible(order)
    end

    context "one line item" do

      context "it is not eligible" do
        it "has no prodct group match and no product type match" do
          allow(rule).to receive_messages(:eligible_product_groups => [product_group_2.id])
          allow(rule).to receive_messages(:eligible_marketing_types => [marketing_type_2.id])
          expect(rule).not_to be_eligible(order)
        end

        it "has a prodct group match and no product type match" do
          allow(rule).to receive_messages(:eligible_product_groups => [product_group_1.id])
          allow(rule).to receive_messages(:eligible_marketing_types => [marketing_type_2.id])
          expect(rule).not_to be_eligible(order)

        end

        it "has no prodct group match and a product type match" do
          allow(rule).to receive_messages(:eligible_product_groups => [product_group_2.id])
          allow(rule).to receive_messages(:eligible_marketing_types => [marketing_type_1.id])
          expect(rule).not_to be_eligible(order)
        end
      end

      
      context "it is eligible" do
        it "has a product group match and a marketing type match" do
          allow(rule).to receive_messages(:eligible_product_groups => [product_group_1.id])
          allow(rule).to receive_messages(:eligible_marketing_types => [marketing_type_1.id])
          expect(rule).to be_eligible(order)
        end
      end
    end

    context "multiple items" do

      let(:line_item_2) { create(:line_item, order: order) }
      let(:product_2) { line_item_2.product }

      before do
        product_2.marketing_type = marketing_type_2
        product_2.product_group = product_group_2 
        product_2.save
      end

      context "it is not eligible" do

        it "If the order satisfies the criteria but not the items" do
          allow(rule).to receive_messages(:eligible_product_groups => [product_group_1.id])
          allow(rule).to receive_messages(:eligible_marketing_types => [marketing_type_2.id])
          expect(rule).not_to be_eligible(order)
        end

      end

      context "it is eligible" do

        it "If the 1 item in the order satisfies the criteria" do
          allow(rule).to receive_messages(:eligible_product_groups => [product_group_1.id, product_group_2.id])
          allow(rule).to receive_messages(:eligible_marketing_types => [marketing_type_1.id, marketing_type_2.id])
          expect(rule).to be_eligible(order)
        end

      end

    end
  end
end


