require 'spec_helper'

module Spree
  module Stock
    describe SupplierQuantifier do

      subject { SupplierQuantifier.new(order, stock_location) }

      let!(:order) { create(:order) }

      context "Simple Order" do

        let!(:supplier) { create(:supplier) }
        let!(:line_item) { create(:line_item, order: order, quantity: 2 ) }

        let(:variant) { line_item.variant }
        let(:stock_location) { variant.stock_locations.first }

        let!(:si) { create(:stock_item, variant: variant, supplier: supplier, stock_location: stock_location, backorderable: false) }

        before do
          variant.stock_items.where.not(id: si.id).delete_all
        end

        it "returns the correct supplier and count" do
          items = subject.pop!(variant, 1)
          expect(items.size).to eq 1
          expect(items.first.supplier).to eq supplier
          expect(items.first.quantity).to eq 1
          expect(items.first.state).to eq :on_hand
        end

        it "does not exceed the required count on the order" do
          items = subject.pop!(variant, 3)
          expect(items.size).to eq 1
          expect(items.first.supplier).to eq supplier
          expect(items.first.quantity).to eq line_item.quantity
          expect(items.first.state).to eq :on_hand
        end

        context "multiple suppliers" do

          let!(:supplier_2) { create(:supplier) }
          let!(:si_2) { create(:stock_item, variant: variant, supplier: supplier_2, stock_location: stock_location, backorderable: false) }

          before do
            si.set_count_on_hand(1)
            si_2.set_count_on_hand(1)
          end

          it "returns the correct supplier and count" do
            items = subject.pop!(variant, 1).to_a
            expect(items.size).to eq 1
            expect([supplier, supplier_2]).to include items.first.supplier
            expect(items.first.quantity).to eq 1
            expect(items.first.state).to eq :on_hand
          end

          it "does not exceed the required count on the order" do
            items = subject.pop!(variant, 3).to_a
            expect(items.size).to eq 2

            expect([supplier, supplier_2]).to include items.first.supplier
            expect([supplier, supplier_2]).to include items.last.supplier
            expect(items.first.supplier).to_not eq items.last.supplier

            expect(items.first.state).to eq :on_hand
            expect(items.last.state).to eq :on_hand

            expect(items.first.quantity).to eq 1
            expect(items.last.quantity).to eq 1
          end

        end

        context "Does not track inventory" do

          before do
            si.set_count_on_hand(0)
            variant.track_inventory = false
          end

          it "returns the correct supplier and count" do
            items = subject.pop!(variant, 2)
            expect(items.size).to eq 1
            expect(items.first.supplier).to eq supplier
            expect(items.first.quantity).to eq 2
            expect(items.first.state).to eq :on_hand
          end

        end

        context "When backordered" do

          before do
            si.set_count_on_hand(1)
            si.backorderable = true
            si.save
            si.supplier = supplier
          end

          it "returns the correct supplier and count" do
            items = subject.pop!(variant, 2)
            expect(items.size).to eq 2

            expect(items.select { |i| i.state == :on_hand }.size).to eq 1
            on_hand = items.first
            expect(on_hand.state).to eq :on_hand
            expect(on_hand.supplier).to eq supplier
            expect(on_hand.quantity).to eq 1

            expect(items.select { |i| i.state == :backordered }.size).to eq 1
            backordered = items.last
            expect(backordered.state).to eq :backordered
            expect(backordered.supplier).to eq supplier
            expect(backordered.quantity).to eq 1

          end

        end

      end


      context "Assmebly" do

        let!(:line_item_1) { create(:line_item, order: order ) }
        let!(:line_item_2) { create(:line_item, order: order ) }

        let!(:part_variant) { create(:base_variant) }

        let!(:stock_location) { part_variant.stock_locations.first }

        let!(:part_for_line_item_1) { create(:part, line_item: line_item_1, variant: part_variant) }
        let!(:part_for_line_item_2) { create(:part, line_item: line_item_2, variant: part_variant) }

        let!(:supplier_1) { create(:supplier) }
        let!(:supplier_2) { create(:supplier) }

        let!(:si_1) { create(:stock_item, variant: part_variant, supplier: supplier_1, stock_location: stock_location, backorderable: false) }
        let!(:si_2) { create(:stock_item, variant: part_variant, supplier: supplier_2, stock_location: stock_location, backorderable: false) }

        before do
          part_variant.stock_items.where.not(id: [si_1.id, si_2.id]).delete_all
          si_1.set_count_on_hand(1)
          si_2.set_count_on_hand(1)
        end

        it "returns the correct supplier and count" do
          items = subject.pop!(part_variant, 1).to_a
          expect(items.size).to eq 1

          expect([supplier_1, supplier_2]).to include items.first.supplier
          expect(items.first.state).to eq :on_hand
          expect(items.first.quantity).to eq 1
        end

        it "does not exceed the required count on the order" do
          items = subject.pop!(part_variant, 3).to_a
          expect(items.size).to eq 2

          expect([supplier_1, supplier_2]).to include items.first.supplier
          expect([supplier_1, supplier_2]).to include items.last.supplier
          expect(items.first.supplier).to_not eq items.last.supplier

          expect(items.first.state).to eq :on_hand
          expect(items.last.state).to eq :on_hand

          expect(items.first.quantity).to eq 1
          expect(items.last.quantity).to eq 1

        end

      end

    end
  end
end
