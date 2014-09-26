require 'spec_helper'

module Spree
  module Stock
    describe AssemblyPrioritizer do
      let(:order) { create(:order_with_line_items, line_items_count: 2) }
      let(:stock_location) { build(:stock_location) }

      let(:line_item1) { order.line_items[0] }
      let(:line_item2) { order.line_items[1] }

      def pack
        package = Package.new(stock_location, order)
        yield(package) if block_given?
        package
      end

      it 'keeps a single package' do
        package1 = pack do |package|
          package.add line_item1, 1, :on_hand
          package.add line_item2, 1, :on_hand
        end

        packages = [package1]
        prioritizer = AssemblyPrioritizer.new(order, packages)
        packages = prioritizer.prioritized_packages
        packages.size.should eq 1
      end

      it 'removes duplicate packages' do
        package1 = pack do |package|
          package.add line_item1, 1, :on_hand
          package.add line_item2, 1, :on_hand
        end
        package2 = pack do |package|
          package.add line_item1, 1, :on_hand
          package.add line_item2, 1, :on_hand
        end

        packages = [package1, package2]
        prioritizer = AssemblyPrioritizer.new(order, packages)
        packages = prioritizer.prioritized_packages
        packages.size.should eq 1
      end

      it 'split over 2 packages' do
        package1 = pack do |package|
          package.add line_item1, 1, :on_hand
        end
        package2 = pack do |package|
          package.add line_item2, 1, :on_hand
        end

        packages = [package1, package2]
        prioritizer = AssemblyPrioritizer.new(order, packages)
        packages = prioritizer.prioritized_packages
        packages.size.should eq 2
      end

      it '1st has some, 2nd has remaining' do
        order.line_items[0].stub(:quantity => 5)
        package1 = pack do |package|
          package.add line_item1, 2, :on_hand
        end
        package2 = pack do |package|
          package.add line_item1, 5, :on_hand
        end

        packages = [package1, package2]
        prioritizer = AssemblyPrioritizer.new(order, packages)
        packages = prioritizer.prioritized_packages
        packages.count.should eq 2
        packages[0].quantity.should eq 2
        packages[1].quantity.should eq 3
      end

      it '1st has backorder, 2nd has some' do
        order.line_items[0].stub(:quantity => 5)
        package1 = pack do |package|
          package.add line_item1, 5, :backordered
        end
        package2 = pack do |package|
          package.add line_item1, 2, :on_hand
        end

        packages = [package1, package2]
        prioritizer = AssemblyPrioritizer.new(order, packages)
        packages = prioritizer.prioritized_packages

        packages[0].quantity(:backordered).should eq 3
        packages[1].quantity(:on_hand).should eq 2
      end

      it '1st has backorder, 2nd has all' do
        order.line_items[0].stub(:quantity => 5)
        package1 = pack do |package|
          package.add line_item1, 3, :backordered
          package.add line_item2, 1, :on_hand
        end
        package2 = pack do |package|
          package.add line_item1, 5, :on_hand
        end

        packages = [package1, package2]
        prioritizer = AssemblyPrioritizer.new(order, packages)
        packages = prioritizer.prioritized_packages
        packages[0].quantity(:backordered).should eq 0
        packages[1].quantity(:on_hand).should eq 5
      end


      describe "line item has parts with the same variant" do
        let(:variant) { create(:variant) }
        let(:part1) { create(:part, variant: variant, quantity: 2, line_item: line_item1) }
        let(:part2) { create(:part, variant: variant, quantity: 1, line_item: line_item1) }

        it 'keeps the quantities of both variants the same' do
          order.line_items[0].stub(:quantity => 3)
          package1 = pack do |package|
            package.add line_item1, 6, :on_hand, variant, nil, part1
            package.add line_item1, 3, :on_hand, variant, nil, part2
          end

          packages = [package1]
          prioritizer = AssemblyPrioritizer.new(order, packages)
          packages = prioritizer.prioritized_packages
          packages.size.should eq 1

          package = packages[0]
          package.find_item(variant, :on_hand, line_item1, nil, part1).quantity.should eq 6
          package.find_item(variant, :on_hand, line_item1, nil, part2).quantity.should eq 3
          package.quantity(:on_hand).should eq 9
          package.quantity(:backordered).should eq 0
        end
      end

    end
  end
end
