require 'spec_helper'

shared_examples_for 'unlimited supply' do
  it 'can_supply? any amount' do
    subject.can_supply?(1).should be_true
    subject.can_supply?(101).should be_true
    subject.can_supply?(100_001).should be_true
  end
end

module Spree
  module Stock
    describe Quantifier do

      before(:all) { Spree::StockLocation.destroy_all } #FIXME leaky database

      let!(:stock_location) { create :stock_location_with_items  }
      let!(:stock_item) { stock_location.stock_items.order(:id).first }

      subject { described_class.new(stock_item.variant) }

      specify { subject.stock_items.should == [stock_item] }


      context 'with a single stock location/item' do
        it 'total_on_hand should match stock_item' do
          subject.total_on_hand.should ==  stock_item.count_on_hand
        end

        context 'when track_inventory_levels is false' do
          before { configure_spree_preferences { |config| config.track_inventory_levels = false } }

          specify { subject.total_on_hand.should == Float::INFINITY }

          it_should_behave_like 'unlimited supply'
        end

        context 'when variant inventory tracking is off' do
          before { stock_item.variant.track_inventory = false }

          specify { subject.total_on_hand.should == Float::INFINITY }

          it_should_behave_like 'unlimited supply'
        end

        context 'when stock item allows backordering' do

          specify { subject.backorderable?.should be_true }

          it_should_behave_like 'unlimited supply'
        end

        context 'when stock item prevents backordering' do
          before { stock_item.update_attributes(backorderable: false) }

          specify { subject.backorderable?.should be_false }

          it 'can_supply? only upto total_on_hand' do
            subject.can_supply?(1).should be_true
            subject.can_supply?(10).should be_true
            subject.can_supply?(11).should be_false
          end
        end

      end

      context 'with multiple stock locations/items' do
        let!(:stock_location_2) { create :stock_location }
        let!(:stock_location_3) { create :stock_location, active: false }

        before do
          stock_location_2.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
          stock_location_3.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
        end

        it 'total_on_hand should total all active stock_items' do
          subject.total_on_hand.should == 15
        end

        context 'when any stock item allows backordering' do
          specify { subject.backorderable?.should be_true }

          it_should_behave_like 'unlimited supply'
        end

        context 'when all stock items prevent backordering' do
          before { stock_item.update_attributes(backorderable: false) }

          specify { subject.backorderable?.should be_false }

          it 'can_supply? upto total_on_hand' do
            subject.can_supply?(1).should be_true
            subject.can_supply?(15).should be_true
            subject.can_supply?(16).should be_false
          end
        end

      end

    end
  end
end

describe Spree::Stock::Quantifier do

  subject {Spree::Stock::Quantifier}

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
  end
end # end describe #can_supply_order?
