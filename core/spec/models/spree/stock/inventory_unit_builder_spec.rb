require 'spec_helper'

module Spree
  module Stock
    describe InventoryUnitBuilder, :type => :model do
      let(:line_item_1) { create(:line_item) }
      let(:line_item_2) { create(:line_item, quantity: 2) }
      let(:order)       { create(:order, line_items: [line_item_1, line_item_2]) }
      let(:variant)     { create(:variant) }
      let(:variant2)    { create(:variant) }
      let!(:part1)      { create(:part, variant: variant, quantity: 2, line_item: line_item_2) }
      let!(:part2)      { create(:part, variant: variant, quantity: 1, line_item: line_item_2) }
      let!(:part3)      { create(:part, variant: variant2, quantity: 1, line_item: line_item_2) }
      let!(:part4)      { create(:part, variant: variant2, quantity: 1, line_item: line_item_2) }

      subject { InventoryUnitBuilder.new(order) }

      before  { line_item_2.product.product_type.update_column(:container, true) }

      describe "#units" do
        context 'ready_to_wear' do
          it "returns an inventory unit for each quantity for the order's line items" do
            units = subject.units
            expect(units.count).to eq 1
            expect(units.map(&:line_item)).to eq [line_item_1]
            expect(units.map(&:variant)).to eq [line_item_1.variant]
          end

          it "builds the inventory units as pending" do
            expect(subject.units.map(&:pending).uniq).to eq [true]
          end

          it "associates the inventory units to the order" do
            expect(subject.units.map(&:order).uniq).to eq [order]
          end

          context "with parts" do
            before do
              line_item_1.parts << part1
              line_item_1.parts << part2
              line_item_1.parts << part3
              line_item_2.product.product_type.update_column(:container, true)
            end

            it "returns an inventory unit for each quantity for the order's line items" do
              units = subject.units
              expect(units.count).to eq 5
              expect(units.first.line_item).to eq line_item_1
              expect(units.first.variant).to eq line_item_1.variant

              expect(units.select { |u| u.line_item == line_item_1 }.size).to eq 5
              expect(units.select { |u| u.variant == variant }.size).to eq 3
              expect(units.select { |u| u.line_item_part == part1 }.size).to eq 2
              expect(units.select { |u| u.line_item_part == part2 }.size).to eq 1
            end
          end
        end

        context 'kit' do
          context "with parts" do
            before do
              line_item_2.parts << part1
              line_item_2.parts << part2
              line_item_2.parts << part3
              allow(part3).to receive(:container?).and_return true
            end

            it "returns an inventory unit for each quantity for the order's line items" do
              units = subject.units
              expect(units.count).to eq 7
              expect(units.first.line_item).to eq line_item_1
              expect(units.first.variant).to eq line_item_1.variant

              expect(units.select { |u| u.line_item == line_item_2 }.size).to eq 6
              expect(units.select { |u| u.variant == variant }.size).to eq 6
              expect(units.select { |u| u.line_item_part == part1 }.size).to eq 4
              expect(units.select { |u| u.line_item_part == part2 }.size).to eq 2
            end
          end
        end
      end
    end
  end
end
