require 'spec_helper'

describe Spree::Stock::Quantifier do
  subject { Spree::Stock::Quantifier }
  let(:kit) { create(:product, product_type: :kit) }
  let(:made_by_the_gang) { create(:product, product_type: :made_by_the_gang) }

  describe "#can_supply_order?" do
    let(:order) { create(:order_with_line_items) }

    it "checks if an order can be supplied" do
      actual_result = subject.can_supply_order?(order)

      expect(actual_result[:in_stock]).to eq true
      expect(actual_result[:errors]).to be_empty
    end

    context "an variant is out of stock" do
      before do
        order.line_items[0].variant.stock_items[0].set_count_on_hand(0)
        order.line_items[0].variant.stock_items[0].backorderable = false
        order.line_items[0].variant.stock_items[0].save
        order.reload
      end
      it "order can no longer be supplied" do
        actual_result = subject.can_supply_order?(order)
        
        expect(actual_result[:in_stock]).to eq false
        expect(actual_result[:errors].size).to eq 1
      end
    end

    context "add variant to order" do
      let(:variant) { create(:variant) }
      let(:adding_rtw) { Spree::LineItem.new(variant_id: variant.id, quantity: 3) }
      let(:adding_kit) {
        li = Spree::LineItem.new(variant_id: variant.id, quantity: 1)
        li.line_item_options = [Spree::LineItemOption.new(variant_id: variant.id, quantity: 5)]
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
