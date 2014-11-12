require 'spec_helper'

module Spree
  module Stock
    describe AvailabilityValidator do
      let(:variant) { create(:variant) }
      let(:extra_variant) { create(:variant) }

      let(:order) { Spree::Order.new(id: 21) }
      let(:line_item) { Spree::LineItem.new(variant: variant, quantity: 2) }
      let(:extra_line_item) { Spree::LineItem.new(variant: extra_variant, quantity: 6) }

      let(:quantifier) { double }

      before do
        order.line_items << line_item
      end

      describe "validation of line item" do

        it 'should be valid when supply is sufficient' do
          Stock::Quantifier.any_instance.stub(can_supply?: true)

          line_item.should_not_receive(:errors)
          subject.validate(line_item).should eq true
        end

        it 'should be invalid when supply is insufficent' do
          Stock::Quantifier.any_instance.stub(can_supply?: false)

          line_item.errors.should_receive(:[]).with(:quantity).and_return []
          subject.validate(line_item).should eq false
        end

        it "does not validate other line items" do
          order.line_items << extra_line_item
          Stock::Quantifier.should_not_receive(:new).with(extra_variant)

          Stock::Quantifier.should_receive(:new).with(variant).and_return quantifier
          quantifier.should_receive(:can_supply?).with(2).and_return true

          line_item.should_not_receive(:errors)
          subject.validate(line_item).should eq true
        end

        context "when variant is required by other line items" do
          before do
            order.line_items << Spree::LineItem.new(variant: variant, quantity: 10)
            line_item.quantity = 0
          end

          it "should not add errors if the line item quantity required is eq to 0" do
            Stock::Quantifier.any_instance.stub(can_supply?: false)

            line_item.should_not_receive(:errors)
            subject.validate(line_item).should eq true
          end
        end

        context "when inventory units exist" do
          before do
            Stock::Quantifier.any_instance.stub(can_supply?: false)
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: false)
          end

          it 'should consider pending inventory units not sufficient' do
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: true)

            line_item.errors.should_receive(:[]).with(:quantity).and_return []
            subject.validate(line_item).should eq false
          end

          it 'should consider non-pending inventory units sufficient' do
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: false)

            line_item.should_not_receive(:errors)
            subject.validate(line_item).should eq true
          end
        end
      end

      describe "validation of an entire order" do
        before do
          order.line_items << extra_line_item
        end

        it 'should show errors for all line_items, which are missing stock' do
          Stock::Quantifier.any_instance.stub(can_supply?: false)

          line_item.errors.should_receive(:[]).with(:quantity).and_return []
          extra_line_item.errors.should_receive(:[]).with(:quantity).and_return []

          subject.validate_order(order).should eq false
        end
      end


      context "with feeder and inactive locations" do
        let!(:inactive_location) { create(:stock_location, active: false) }
        let!(:active_location) { variant.stock_items.first.stock_location }
        let!(:feeder_location) { create(:stock_location, active: false, feed_into: active_location) }

        let(:available_stock_locations) { [active_location, feeder_location] }

        let(:stock_items) {
          variant.stock_items.select do |si|
            available_stock_locations.include?(si.stock_location)
          end
        }

        it "only passes stock items from feeder and active locations into the Quantifier" do
          expect(Stock::Quantifier).to receive(:new) do |call_variant, call_items|
            expect(call_variant).to eq(variant)
            expect(call_items.map(&:id)).to match_array(stock_items.map(&:id))
          end.and_call_original
          subject.validate_order(order)
        end
      end

    end
  end
end
