require 'spec_helper'

module Spree
  module Stock
    describe Packer do
      let!(:order) { create(:order_with_line_items, line_items_count: 5) }
      let(:stock_location) { create(:stock_location) }
      let(:default_splitters) { Rails.application.config.spree.stock_splitters }

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
          packages.first.contents.size.should eq 5
        end

        it 'allows users to set splitters to an empty array' do
          packages = Packer.new(stock_location, order, []).packages
          packages.size.should eq 1
        end
      end

      context 'default_package' do
        it 'contains all the items' do
          package = subject.default_package
          package.contents.size.should eq 5
          package.weight.should > 0
        end

        it 'variants are added as backordered without enough on_hand' do
          stock_location.should_receive(:fill_status).exactly(5).times.and_return([2,3])

          package = subject.default_package
          package.on_hand.size.should eq 5
          package.backordered.size.should eq 5
        end

        context "location doesn't have order items in stock" do
          let(:stock_location) { create(:stock_location, propagate_all_variants: false) }
          let(:packer) { Packer.new(stock_location, order) }

          it "builds an empty package" do
            packer.default_package.contents.should be_empty
          end
        end

        context "doesn't track inventory levels" do
          let(:order) { Order.create }
          let!(:line_item) { order.contents.add(create(:variant), 30) }

          before { Config.track_inventory_levels = false }

          it "doesn't bother stock items status in stock location" do
            expect(subject.stock_location).not_to receive(:fill_status)
            subject.default_package
          end

          it "still creates package with proper quantity" do
            expect(subject.default_package.quantity).to eql 30
          end
        end
      end

      # from spree product assembly for adding the parts along with 
      # the main line item to the inventory units table
      context 'build bundle product package' do
        let!(:parts) { (1..3).map { create(:part, line_item: order.line_items.first) } }

        it 'adds all bundle parts to the shipment' do
          package = subject.product_assembly_package
          package.contents.size.should eq 5 + parts.count
        end

        context "order has backordered and on hand items" do
          before do
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
            package.contents.size.should eq 5 + parts.count
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
            package.contents.size.should eq 5 + parts.count
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
          
          it 'adds items as on-hand, not backordered' do
            package = subject.product_assembly_package
            package.contents.size.should eq 5 + parts.count
            package.contents.each {|ci| ci.state.should eq :on_hand}
          end
        end
      end

    end
  end
end
