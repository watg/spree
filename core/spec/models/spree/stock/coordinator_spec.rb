require 'spec_helper'

module Spree
  module Stock
    describe Coordinator, :type => :model do
      let(:order) { create(:order_with_line_items, line_items_count: 1) }

      subject { Coordinator.new(order) }

      context "packages" do
        it "builds, prioritizes and estimates" do
          expect(subject).to receive(:build_packages).ordered
          expect(subject).to receive(:prioritize_packages).ordered
          expect(subject).to receive(:estimate_packages).ordered
          subject.packages
        end
      end

      describe "#shipments" do
        let(:packages) { [build(:stock_package_fulfilled), build(:stock_package_fulfilled)] }

        before { allow(subject).to receive(:packages).and_return(packages) }

        it "turns packages into shipments" do
          shipments = subject.shipments
          expect(shipments.count).to eq packages.count
          shipments.each { |shipment| expect(shipment).to be_a Shipment }
        end

        it "puts the order's ship address on the shipments" do
          shipments = subject.shipments
          shipments.each { |shipment| expect(shipment.address).to eq order.ship_address }
        end
      end

      context "build packages" do
        it "builds a package for every stock location" do
          subject.packages.count == StockLocation.count
        end

        context "missing stock items in stock location" do
          let!(:another_location) { order.reload; create(:stock_location, propagate_all_variants: false) }

          it "builds packages only for valid stock locations" do
            expect(subject.build_packages.count).to eq(StockLocation.count - 1)
          end
        end
      end

      # from spree product assembly
      context "order shares variant as individual and within bundle" do
        let(:line_item) { order.line_items.first }
        let(:second_line_item) { create(:line_item, order: order) }
        let!(:parts) { (1..3).map { create(:part, line_item: line_item) } }

        let(:bundle_variant) { line_item.variant }
        let(:common_product) { second_line_item.variant }
        let(:supplier) { create(:supplier)}

        before do
          expect(bundle_variant).to_not eql common_product

          # at this point the parts table should contain 4 items (3 parts + 1 common product)
          create(:part, line_item: line_item, variant: common_product)
        end

        before { StockItem.update_all count_on_hand: 10, supplier_id: supplier.id }

        context "bundle part requires more units than individual product" do
          before { order.contents.add_by_line_item(line_item, 5) }

          let!(:bundle_item_quantity) { order.reload.find_line_item_by_variant(bundle_variant).quantity }

          it "calculates items quantity properly" do
            expect(bundle_item_quantity).to eq 6
            expect(line_item.parts.to_a.sum(&:quantity)).to eq 4
            expect(order.line_items.to_a.sum(&:quantity)).to eq 7

            line_items_without_parts = order.line_items.to_a.sum(&:quantity) - bundle_item_quantity
            expected_units_on_package = line_items_without_parts + (line_item.parts.to_a.sum(&:quantity) * bundle_item_quantity)

            expect(subject.packages.sum(&:quantity)).to eql expected_units_on_package
          end
        end
      end

      context "multiple stock locations" do
        let!(:stock_locations) { (1..3).map { create(:stock_location) } }

        let!(:line_item) { order.line_items.first }
        let!(:parts) { (1..3).map { create(:part, line_item: line_item) } }

        let(:bundle_variant) { line_item.variant }

        let(:bundle_item_quantity) { order.find_line_item_by_variant(bundle_variant).quantity }

        it "calculates items quantity properly" do
          expect(bundle_item_quantity).to eq 1
          line_items_without_parts = order.line_items.to_a.sum(&:quantity) - bundle_item_quantity
          expected_units_on_package = line_items_without_parts + (parts.count * bundle_item_quantity)
          expect(subject.packages.sum(&:quantity)).to eql expected_units_on_package

        end
      end

    end
  end
end
