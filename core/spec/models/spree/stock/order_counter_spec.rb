require 'spec_helper'

module Spree
  module Stock
    describe OrderCounter do
      let(:variant1) { mock_model(Spree::Variant) }
      let(:variant2) { mock_model(Spree::Variant) }

      let(:order) { order = mock_model(Spree::Order, line_items: [], inventory_units: [])
                    order.line_items << mock_model(Spree::LineItem, variant: variant1 , quantity: 2)
                    order.line_items << mock_model(Spree::LineItem, variant: variant2, quantity: 2)
                    order.inventory_units << mock_model(Spree::InventoryUnit, order: order, variant: variant1)
                    order.inventory_units << mock_model(Spree::InventoryUnit, order: order, variant: variant2)
                    order.inventory_units << mock_model(Spree::InventoryUnit, order: order, variant: variant2)
                    order }

      subject { OrderCounter.new(order) }

      describe '#variants' do
        subject { super().variants }
        it { is_expected.to eq [variant1, variant2] }
      end

      describe '#variants_with_remaining' do
        subject { super().variants_with_remaining }
        it { is_expected.to eq [variant1] }
      end
      it { is_expected.to be_remaining }

      it 'counts ordered' do
        expect(subject.ordered(variant1)).to eq 2
        expect(subject.ordered(variant2)).to eq 2
      end

      it 'counts assigned' do
        expect(subject.assigned(variant1)).to eq 1
        expect(subject.assigned(variant2)).to eq 2
      end

      it 'counts remaining' do
        expect(subject.remaining(variant1)).to eq 1
        expect(subject.remaining(variant2)).to eq 0
      end


      # Regression test for #3744
      context "works with a persisted order" do
        let(:order) { create(:completed_order_with_totals, :line_items_count => 1) }
        let(:variant1) { order.variants.first }

        it 'does not raise NoMethodError for Order#inventory_units' do
          expect(subject.ordered(variant1)).to eq 1
        end
      end
    end
  end
end
