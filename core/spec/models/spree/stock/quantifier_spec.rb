require 'spec_helper'

describe Spree::Stock::Quantifier do
  subject { Spree::Stock::Quantifier }

  describe "#can_supply_order?" do
    let(:order) { create(:order) }
    let(:line_item) { create(:line_item, order: order) }

    it "checks if an order can be supplied" do
      actual_result = subject.can_supply_order?(order)

      expect(actual_result[:in_stock]).to eq true
      expect(actual_result[:errors]).to be_empty
    end

    context "an variant is out of stock" do
      before do
        line_item.variant.stock_items[0].set_count_on_hand(0)
        line_item.variant.stock_items[0].backorderable = false
        line_item.variant.stock_items[0].save
        line_item.reload
      end
      it "order can no longer be supplied" do
        actual_result = subject.can_supply_order?(order)
        
        expect(actual_result[:in_stock]).to eq false
        out_of_stock_line_item = actual_result[:errors].map {|li| li[:line_item_id] }
        expect(out_of_stock_line_item).to match_array([order.line_items[0].id])
      end
    end

    context "add variant to order" do
      let(:variant) { create(:variant) }
      let(:adding_rtw) { Spree::LineItem.new(variant_id: variant.id, quantity: 3) }
      let(:adding_kit) {
        li = Spree::LineItem.new(variant_id: variant.id, quantity: 1)
        li.line_item_parts = [Spree::LineItemPart.new(variant_id: variant.id, quantity: 5)]
        li
      }
      before do
        variant.stock_items.first.backorderable = false
        variant.stock_items.first.save
        variant.stock_items.first.set_count_on_hand(4)
        variant.stock_items.first.save
      end

      it "adding simple variant" do
        actual_result = subject.can_supply_order?(order, adding_rtw)
        
        expect(actual_result[:in_stock]).to eq true
        expect(actual_result[:errors]).to be_empty        
      end

      it "adding kit variant" do
        pending("variant is backorderable")
        actual_result = subject.can_supply_order?(order, adding_kit)
        
        expect(actual_result[:in_stock]).to eq false
        expect(actual_result[:errors].size).to eq 1      
      end
    end
  end
end
