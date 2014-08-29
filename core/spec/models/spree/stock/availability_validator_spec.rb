require 'spec_helper'

module Spree
  module Stock
    describe AvailabilityValidator do
      let(:variant) { create(:variant) }
      let(:order) { Spree::Order.new(id: 21) }
      let!(:line_item) { Spree::LineItem.new(variant_id: variant.id, quantity: 2, order: order) }

      describe "validating one line item" do

        it 'should be valid when supply is sufficient' do
          Stock::Quantifier.any_instance.stub(can_supply?: true)

          line_item.should_not_receive(:errors)
          subject.validate(line_item)
        end

        it 'should be invalid when supply is insufficent' do
          Stock::Quantifier.any_instance.stub(can_supply?: false)

          line_item.errors.should_receive(:[]).with(:quantity).and_return []
          subject.validate(line_item)
        end

        it 'should consider existing inventory_units sufficient' do
          Stock::Quantifier.any_instance.stub(can_supply?: false)
          Spree::InventoryUnit.create(variant_id: variant.id, order: order)
          Spree::InventoryUnit.create(variant_id: variant.id, order: order)

          line_item.should_not_receive(:errors)

          subject.validate(line_item)
        end
      end

      describe "validating the entire order with parts and other line items" do
        let(:extra_variant) { create(:variant) }
        let(:extra_line_item) { create(:line_item, variant_id: extra_variant.id, quantity: 1, order: order) }
        let(:part) { Spree::LineItemPart.new(variant_id: extra_variant.id, quantity: 3) }
        let(:container_part) { Spree::LineItemPart.new(variant_id: extra_variant.id, quantity: 10, container: true) }
        let(:quantifier) { double }

        before do
          order.line_items << extra_line_item
          line_item.line_item_parts << part
          line_item.line_item_parts << container_part
        end

        it "should be valid if the sum of all physical parts is suppliable" do
          # for the parts (2 * 3) and the extra line item + 1
          Stock::Quantifier.should_receive(:new).with(extra_variant).and_return quantifier
          quantifier.should_receive(:can_supply?).with(7).and_return true

          line_item.should_not_receive(:errors)
          subject.validate(line_item)
        end

        it "should be invalid if a part is missing stock" do
          Stock::Quantifier.should_receive(:new).with(extra_variant).and_return quantifier
          quantifier.should_receive(:can_supply?).with(7).and_return false

          line_item.errors.should_receive(:[]).with(:quantity).and_return []
          subject.validate(line_item)
        end

        it "should be valid if some of the parts have reserved inventory units" do
          Spree::InventoryUnit.create(variant_id: extra_variant.id, order: order)

          Stock::Quantifier.should_receive(:new).with(extra_variant).and_return quantifier
          quantifier.should_receive(:can_supply?).with(6).and_return true

          line_item.should_not_receive(:errors)
          subject.validate(line_item)
        end

      end

    end
  end
end
