require 'spec_helper'

module Spree
  module Stock
    describe Packer do

      let(:variant) { build(:base_variant) }
      let(:order) { build(:order) }

      let!(:inventory_units) { 5.times.map { build(:inventory_unit, line_item: nil, order: order) } }
      let(:stock_location) { create(:stock_location) }
      let(:default_splitters) { Rails.application.config.spree.stock_splitters }

      subject { Packer.new(stock_location, inventory_units) }

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
          packages.first.contents.size.should eq 5
        end

        it 'allows users to set splitters to an empty array' do
          packages = Packer.new(stock_location, inventory_units, []).packages
          packages.size.should eq 1
        end
      end

      context 'default_package' do
        it 'contains all the items' do
          package = subject.product_assembly_package
          package.contents.size.should eq 5
          package.weight.should > 0
        end

        it 'variants are added as backordered without enough on_hand' do
          stock_location.should_receive(:fill_status).exactly(5).times.and_return(
            *(Array.new(3, [1,0]) + Array.new(2, [0,1]))
          )

          package = subject.product_assembly_package
          package.on_hand.size.should eq 3
          package.backordered.size.should eq 2
        end

        context "location doesn't have order items in stock" do
          let(:stock_location) { create(:stock_location, propagate_all_variants: false) }
          let(:packer) { Packer.new(stock_location, inventory_units) }

          it "builds an empty package" do
            packer.product_assembly_package.contents.should be_empty
          end
        end

        context "doesn't track inventory levels" do
          let(:variant) { build(:variant) }
          let!(:inventory_units) { 30.times.map { build(:inventory_unit, line_item: nil, variant: variant, order: order) } }

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

    end
  end
end
