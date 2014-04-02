require 'spec_helper'

module Spree
  describe OrderInventoryAssembly do
    let(:order) { create(:order_with_line_items, line_items_count: 1) }
    let(:line_item) { order.line_items.first }
    let(:bundle) { line_item.product }
    let(:parts) { (1..3).map { create(:part, line_item: line_item) } }

    before do
      parts.first.update_column(:quantity, 3)

      line_item.update_attributes!(quantity: 3)
      order.reload.create_proposed_shipments
      order.finalize!
      # subject.verify
    end

    subject { OrderInventoryAssembly.new(line_item) }

    context "inventory units count" do
      it "calculates the proper value for the line item + parts" do
        expected_units_count = line_item.quantity * parts.to_a.sum(&:quantity) + line_item.quantity
        expect(subject.inventory_units.count).to eql(expected_units_count)
      end
    end

    context "verify line item units" do
      let!(:original_units_count) { subject.inventory_units.count }

      context "quantity increases" do
        before { subject.line_item.quantity += 1 }

        it "inserts new inventory units for every bundle part" do
          expected_units_count = original_units_count + parts.to_a.sum(&:quantity)
          subject.verify
          expect(OrderInventoryAssembly.new(line_item.reload).inventory_units.count).to eql(expected_units_count)
        end
      end

      context "quantity decreases" do
        before { subject.line_item.quantity -= 1 }

        it "remove inventory units for every bundle part" do
          expected_units_count = original_units_count - parts.to_a.sum(&:quantity)
          subject.verify

          # needs to reload so that inventory units are fetched from updates order.shipments
          updated_units_count = OrderInventoryAssembly.new(line_item.reload).inventory_units.count
          expect(updated_units_count).to eql(expected_units_count)
        end
      end
    end
  end
end

