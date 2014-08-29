require 'spec_helper'

describe Spree::Stock::Quantifier do
  subject { Spree::Stock::Quantifier }

  describe "#can_supply_order?" do
    let(:order) { create(:order) }
    let(:line_item) { create(:line_item, order: order) }

    it "checks if an order can be supplied" do
      result = subject.can_supply_order?(order)

      expect(result[:in_stock]).to eq true
      expect(result[:errors]).to be_empty
    end

    context "a variant is out of stock" do
      before do
        stock_item = line_item.variant.stock_items[0]
        stock_item.backorderable = false
        stock_item.save!
      end

      it "order can no longer be supplied" do
        result = subject.can_supply_order?(order)

        expect(result[:in_stock]).to eq false
        out_of_stock_line_item = result[:errors].map {|li| li[:line_item_id] }
        expect(out_of_stock_line_item).to eq([order.line_items.first.id])
      end
    end

    context "when adding a new line item to an order" do
      let(:variant) { create(:variant) }
      let(:stock_item) { variant.stock_items.first }
      before do
        allow_any_instance_of(Spree::StockItem).to receive(:backorderable).and_return(false)
      end

      context "when the line item does not have parts" do
        let(:line_item_without_parts) { Spree::LineItem.new(variant_id: variant.id, quantity: 2, order: order) }

        it "it is able to supply the order when the stock item quantity is enough" do
          stock_item.set_count_on_hand(2)
          result = subject.can_supply_order?(order, line_item_without_parts)

          expect(result[:in_stock]).to eq true
          expect(result[:errors]).to be_empty
        end

        it "it returns errors when the stock item quantity is not enough" do
          stock_item.set_count_on_hand(1)
          result = subject.can_supply_order?(order, line_item_without_parts)

          expect(result[:in_stock]).to eq false
          expect(result[:errors].size).to eq 1
        end
      end

      context "when the line item has parts" do
        let!(:line_item_with_parts) { Spree::LineItem.new(variant_id: variant.id, quantity: 2, order: order) }

        before do
          line_item_with_parts.line_item_parts << Spree::LineItemPart.new(variant_id: variant.id, quantity: 3)
        end

        it "it is able to supply the order when the stock item quantity is enough" do
          stock_item.set_count_on_hand(8)
          result = subject.can_supply_order?(order, line_item_with_parts)

          expect(result[:in_stock]).to eq true
          expect(result[:errors]).to be_empty
        end

        it "it returns errors when the stock item quantity is not enough" do
          stock_item.set_count_on_hand(7)
          result = subject.can_supply_order?(order, line_item_with_parts)

          expect(result[:in_stock]).to eq false
          expect(result[:errors].size).to eq 2 # 2 because both the container and the part are out of stock
        end

        context "when some of tha parts are containers" do

          before do
            line_item_with_parts.line_item_parts << Spree::LineItemPart.new(variant_id: variant.id, quantity: 5, container: true)
          end

          it "does not consider them relevant for the stock check" do
            stock_item.set_count_on_hand(8)
            result = subject.can_supply_order?(order, line_item_with_parts)

            expect(result[:in_stock]).to eq true
            expect(result[:errors]).to be_empty
          end
        end
      end

    end
  end # end describe #can_supply_order?
end
