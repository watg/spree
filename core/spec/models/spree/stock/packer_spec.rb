require 'spec_helper'

module Spree
  module Stock
    describe Packer do
      let(:number_of_line_items) { 6 }
      let!(:order) { create(:order_with_line_items, line_items_count: number_of_line_items) }
      let(:stock_location) { create(:stock_location) }
      let(:default_splitters) { Rails.application.config.spree.stock_splitters }
      let(:supplier) { create(:supplier) }

      subject { Packer.new(stock_location, order, default_splitters) }

      before do
        Rails.application.config.spree.stock_splitters = [
          Spree::Stock::Splitter::ShippingCategory,
          Spree::Stock::Splitter::Backordered
        ]
      end

      context 'packages' do
        it 'builds an array of packages' do
          packages = subject.packages
          packages.size.should eq 1
          packages.first.contents.size.should eq number_of_line_items
        end

        it 'allows users to set splitters to an empty array' do
          packages = Packer.new(stock_location, order, []).packages
          packages.size.should eq 1
        end
      end

      context 'default_package' do
        it 'contains all the items' do
          package = subject.product_assembly_package
          package.contents.size.should eq number_of_line_items
          package.weight.should > 0
        end

        it 'variants are added as backordered without enough on_hand' do
          # Note we return nil as fill_status should not return backordered in the
          # future
          stock_location.stock_items.map do |si|
            si.backorderable = true
            si.supplier = supplier
            si.set_count_on_hand(1)
          end
          order.line_items.map { |li| li.quantity = 2 }

          package = subject.product_assembly_package
          package.on_hand.size.should eq number_of_line_items
          package.backordered.size.should eq number_of_line_items
        end

        context "location doesn't have order items in stock" do
          let(:stock_location) { create(:stock_location, propagate_all_variants: false) }
          let(:packer) { Packer.new(stock_location, order) }

          it "builds an empty package" do
            packer.product_assembly_package.contents.should be_empty
          end
        end

        context "doesn't track inventory levels" do
          let(:order) { Order.create }
          let!(:line_item) { order.contents.add(create(:variant), 30) }

          before { Config.track_inventory_levels = false }

          it "doesn't bother stock items status in stock location" do
            expect(subject.stock_location).not_to receive(:fill_status)
            subject.product_assembly_package
          end

          it "still creates package with proper quantity" do
            expect(subject.product_assembly_package.quantity).to eql 30
          end
        end
      end

      # from spree product assembly for adding the
      # parts only to the inventory units table
      context 'build bundle product package' do
        let!(:parts) { (1..3).map { create(:part, line_item: order.line_items.first) } }
        let!(:container_part) { create(:part, line_item: order.line_items.first, container: true) }
        let(:number_of_line_items_with_parts) { 1 }

        it 'adds all bundle parts to the shipment' do
          package = subject.product_assembly_package
          package.contents.size.should eq number_of_line_items + parts.count - number_of_line_items_with_parts
        end

        context "order has backordered and on hand items" do
          before do
            stock_location.stock_items.update_all(supplier_id: supplier.id)
            stock_item = stock_location.stock_item(parts.first.variant)
            stock_item.adjust_count_on_hand(10)
          end

          it "splits package in two as expected (backordered, on_hand)" do
            expect(subject.packages.count).to eql 2
          end
        end

        context "store doesn't track inventory" do
          before { Spree::Config.track_inventory_levels = false }

          it 'adds items as on-hand, not backordered' do
            stock_item = stock_location.stock_item(order.line_items.first)

            package = subject.product_assembly_package
            package.contents.size.should eq number_of_line_items + parts.count - number_of_line_items_with_parts
            package.contents.each {|ci| ci.state.should eq :on_hand}
          end
        end

        context "are tracking inventory" do
          before do
            Spree::Config.track_inventory_levels = true
            # by default, variant factory sets track_inventory to true
          end

          it 'adds items as backordered' do
            package = subject.product_assembly_package
            package.contents.size.should eq number_of_line_items + parts.count - number_of_line_items_with_parts
            package.contents.each {|ci| ci.state.should eq :backordered}
          end
        end

        context 'variants and parts do not track inventory' do
          before(:each) do
            Spree::Config.track_inventory_levels = true
            order.line_items.each do |li|
              li.variant.track_inventory = false
              li.save!
              if li.parts.any?
                li.parts.each do |part|
                  part.variant.track_inventory = false
                  part.variant.save!
                end
              end
            end
          end

          let(:supplier) { create(:supplier) }

          before do
            stock_location.stock_items.map { |si| si.supplier = supplier; si.save }
          end

          it 'adds items as on-hand, not backordered' do
            package = subject.product_assembly_package
            package.contents.size.should eq number_of_line_items + parts.count - number_of_line_items_with_parts
            package.contents.each {|ci| ci.state.should eq :on_hand}
            package.contents.each {|ci| ci.supplier.should eq supplier}
          end
        end
      end

      # Test Fix For: if an order has 2 line items which are kits and they have a common
      # variants e.g.(  a blue zion lion ) but the stock count is SupplierA: 1, SupplierB: 1
      # for the common part. Before the fix it would have decremented 2 from SupplierA to leave
      # it as -1 due to the fact it did not take the whole order into account when determining
      # the supplier stock.
      context "Supplier and Assemblies" do
        let!(:order) { create(:order) }
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
          order.line_items.reload
          si_1.set_count_on_hand(1)
          si_2.set_count_on_hand(1)
        end

        it "removes stock from both suppliers when there is not enough stock from one" do

          package = subject.product_assembly_package
          expect(package.contents.size).to eq 2

          package_1 = package.contents.detect { |p| p.line_item_part == part_for_line_item_1 }
          expect(package_1.variant).to eq part_variant
          expect(package_1.quantity).to eq 1
          expect([supplier_1, supplier_2]).to include(package_1.supplier)

          package_2 = package.contents.detect { |p| p.line_item_part == part_for_line_item_2 }
          expect(package_2.variant).to eq part_variant
          expect(package_2.quantity).to eq 1
          expect([supplier_1, supplier_2]).to include(package_2.supplier)

          expect(package_1.supplier).to_not eq package_2.supplier
        end

      end

    end
  end
end
