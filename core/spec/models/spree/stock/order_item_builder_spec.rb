require 'spec_helper'

module Spree
  module Stock
    describe OrderItemBuilder do
      subject { OrderItemBuilder.new(line_items) }

      let(:variant_id) { 15 }
      let(:extra_variant_id) { 16 }

      let(:line_item) { Spree::LineItem.new(variant_id: variant_id, quantity: 2) }
      let(:extra_line_item) { Spree::LineItem.new(variant_id: extra_variant_id, quantity: 1) }
      let(:line_items) {[]}

      let(:part1) { Spree::LineItemPart.new(variant_id: variant_id, quantity: 3) }
      let(:part2) { Spree::LineItemPart.new(variant_id: extra_variant_id, quantity: 4) }
      let!(:container_part) { Spree::LineItemPart.new(variant_id: extra_variant_id, quantity: 10) }

      let(:expected_item_1) { Spree::Stock::OrderItemBuilder::Item.new(variant_id, line_item, 6) }
      let(:expected_item_2) { Spree::Stock::OrderItemBuilder::Item.new(extra_variant_id, line_item, 8) }
      let(:expected_item_3) { Spree::Stock::OrderItemBuilder::Item.new(extra_variant_id, extra_line_item, 1) }

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

      it "builds a flat list of items" do
        items = subject.items
        expect(items.count).to eq 3
        expect(items[0]).to eq expected_item_1
        expect(items[1]).to eq expected_item_2
        expect(items[2]).to eq expected_item_3
      end

      it "groups all variants by count" do
        variants = subject.group_variants
        expect(variants.count).to eq 2
        expect(variants[variant_id]).to eq 6
        expect(variants[extra_variant_id]).to eq 9 # 1 + 9
      end

      it "returns the items with a matching variant" do
        items = subject.find_by_variant_id(extra_variant_id)
        expect(items.count).to eq 2
        expect(items[0]).to eq expected_item_2
        expect(items[1]).to eq expected_item_3
      end

      it "#variant_ids_for_line_item" do
        variants = subject.variant_ids_for_line_item(line_item)
        expect(variants.count).to eq 2
        expect(variants[0]).to eq variant_id
        expect(variants[1]).to eq extra_variant_id
      end


    end
  end
end
