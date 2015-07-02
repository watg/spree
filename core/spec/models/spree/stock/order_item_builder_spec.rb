require 'spec_helper'

module Spree
  module Stock
    describe OrderItemBuilder do
      subject { OrderItemBuilder.new(line_items) }

      let(:variant)       { create(:variant, id: 15) }
      let(:extra_variant) { create(:variant, id: 16) }

      let(:line_item) { Spree::LineItem.new(variant: variant, quantity: 2) }
      let(:extra_line_item) { Spree::LineItem.new(variant: extra_variant, quantity: 1) }
      let(:line_items) {[]}

      let(:part1) { Spree::LineItemPart.new(variant_id: variant_id, quantity: 3) }
      let(:part2) { Spree::LineItemPart.new(variant_id: extra_variant.id, quantity: 4) }
      let!(:container_part) { Spree::LineItemPart.new(variant_id: extra_variant.id, quantity: 10) }
      let(:expected_item) { Spree::Stock::OrderItemBuilder::Item.new(variant.id, line_item, 2) }
      let(:expected_item_1) { Spree::Stock::OrderItemBuilder::Item.new(variant.id, line_item, 6) }
      let(:expected_item_2) { Spree::Stock::OrderItemBuilder::Item.new(extra_variant.id, line_item, 8) }
      let(:expected_item_3) { Spree::Stock::OrderItemBuilder::Item.new(extra_variant.id, extra_line_item, 1) }

      before do
        allow(part1).to receive(:container?).and_return false
        allow(part2).to receive(:container?).and_return false
        allow(container_part).to receive(:container?).and_return true
        line_item.line_item_parts << part1
        line_item.line_item_parts << part2
        line_item.line_item_parts << container_part

        line_items << line_item
        line_items << extra_line_item
      end

      context 'ready to wear with parts' do
        context do
          it "builds items for line item and parts" do
            items = subject.items
            expect(items.count).to eq 4
            expect(items[0]).to eq expected_item
            expect(items[1]).to eq expected_item_1
            expect(items[2]).to eq expected_item_2
            expect(items[3]).to eq expected_item_3
          end

          it "groups all variants by count" do
            variants = subject.group_variants
            expect(variants.count).to eq 2
            expect(variants[variant.id]).to eq 8
            expect(variants[extra_variant.id]).to eq 9
          end

          it "returns the items with a matching variant" do
            items = subject.find_by_variant_id(extra_variant.id)
            expect(items.count).to eq 2
            expect(items[0]).to eq expected_item_2
            expect(items[1]).to eq expected_item_3
          end

          it "returns the items with a matching variant" do
            items = subject.find_by_variant_id(extra_variant.id)
            expect(items.count).to eq 2
            expect(items[0]).to eq expected_item_2
            expect(items[1]).to eq expected_item_3
          end

          it "#variant_ids_for_line_item" do
            variants = subject.variant_ids_for_line_item(line_item)
            expect(variants.count).to eq 3
            expect(variants[0]).to eq variant.id
            expect(variants[1]).to eq variant.id
            expect(variants[2]).to eq extra_variant.id
          end
        end
      end

      context 'kit' do
        before { line_item.variant.product.product_type.update_column(:name, 'kit') }

        context do
          it "builds items for parts only" do
            items = subject.items
            expect(items.count).to eq 3
            expect(items[0]).to eq expected_item_1
            expect(items[1]).to eq expected_item_2
            expect(items[2]).to eq expected_item_3
          end
        end
      end
    end
  end
end
