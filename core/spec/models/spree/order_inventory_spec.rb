require 'spec_helper'

module Spree
  describe OrderInventory do
    let(:order) { create :completed_order_with_totals }
    let(:line_item) { order.line_items.first }

    subject { described_class.new(order, line_item) }

    context "when order is missing inventory units" do
      before { line_item.update_column(:quantity, 2) }

      it 'creates the proper number of inventory units' do
        subject.verify
        expect(subject.inventory_units.count).to eq 2
      end
    end

    context "#add_to_shipment" do
      let(:shipment) { order.shipments.first }

      context "order is not completed" do
        before { order.stub complete?: false }

        it "doesn't unstock items" do
          shipment.stock_location.should_not_receive(:unstock)
          subject.send(:add_to_shipment, shipment, 5).should == 5
        end
      end

      context "inventory units line_item_part_id" do

        before do
          rtn = [
            [OpenStruct.new( supplier: nil, count: 3 )],
            [OpenStruct.new( supplier: nil, count: 2 )],
          ]
          shipment.stock_location.should_receive(:fill_status).with(subject.variant, 5).and_return(rtn)
        end


        it "should be nil for non assembly items" do
          subject.send(:add_to_shipment, shipment, 5).should == 5
          units = shipment.inventory_units_for(subject.variant).select { |u| !u.line_item_part.nil? }
          expect(units.size).to eq 0
        end

      end

      context "inventory units state" do
        before do
          shipment.inventory_units.destroy_all
        end

        it 'sets inventory_units state as per stock location availability' do
          rtn = [
            [OpenStruct.new( supplier: nil, count: 3 )],
            [OpenStruct.new( supplier: nil, count: 2 )],
          ]
          shipment.stock_location.should_receive(:fill_status).with(subject.variant, 5).and_return(rtn)

          subject.send(:add_to_shipment, shipment, 5).should == 5

          units = shipment.inventory_units_for(subject.variant).group_by(&:state)
          units['backordered'].size.should == 2
          units['on_hand'].size.should == 3
        end
      end

      context "inventory units state with suppliers" do
        let(:supplier_1) { create :supplier }
        let(:supplier_2) { create :supplier }

        before do
          shipment.inventory_units.destroy_all
        end

        it 'sets inventory_units state as per stock location availability' do
          rtn = [
            [
              OpenStruct.new( supplier: nil, count: 1),
              OpenStruct.new( supplier: supplier_1, count: 3 ),
              OpenStruct.new( supplier: supplier_2, count: 4)
            ],
            [
              OpenStruct.new( supplier: nil, count: 2),
              OpenStruct.new( supplier: supplier_1, count: 2 ),
              OpenStruct.new( supplier: supplier_2, count: 3)
            ],
          ]
          shipment.stock_location.should_receive(:fill_status).with(subject.variant, 15).and_return(rtn)

          subject.send(:add_to_shipment, shipment, 15).should == 15

          # A helper to group the units so we can easily test the quantities
          units = shipment.inventory_units_for(subject.variant).inject({}) do |h,unit|
            h[unit.state] ||= {}
            h[unit.state][unit.supplier] ||= 0
            h[unit.state][unit.supplier] += 1
            h
          end

          units['on_hand'][nil].should == 1
          units['on_hand'][supplier_1].should == 3
          units['on_hand'][supplier_2].should == 4
          units['backordered'][nil].should == 2
          units['backordered'][supplier_1].should == 2
          units['backordered'][supplier_2].should == 3
        end

      end

      context "store doesnt track inventory" do
        let(:variant) { create(:variant) }

        before { Spree::Config.track_inventory_levels = false }

        it "creates only on hand inventory units" do
          variant.stock_items.destroy_all

          # The before_save callback in LineItem would verify inventory
          line_item = order.contents.add variant, 1, nil, shipment: shipment

          units = shipment.inventory_units_for(line_item.variant)
          expect(units.count).to eq 1
          expect(units.first).to be_on_hand
        end
      end

      context "variant doesnt track inventory" do
        let(:variant) { create(:variant) }
        let(:supplier) { create(:supplier) }

        before do
          shipment.stock_location.stock_items.map { |si| si.supplier = supplier }
          variant.track_inventory = false
          variant.stock_items.map { |si| si.supplier = supplier; si.save }
        end

        it "creates only on hand inventory units" do
          line_item = order.contents.add variant, 1
          subject.verify(shipment)

          units = shipment.inventory_units_for(line_item.variant)
          expect(units.count).to eq 1
          expect(units.first).to be_on_hand
          expect(units.first.supplier).to eq supplier
        end
      end

      it 'should create stock_movement' do
        subject.send(:add_to_shipment, shipment, 5).should == 5

        stock_item = shipment.stock_location.stock_item(subject.variant)
        movement = stock_item.stock_movements.last
        # movement.originator.should == shipment
        movement.quantity.should == -5
      end

      context "line_item_parts" do


      end

      context "suppliers" do

        let(:stock_item) { shipment.stock_location.stock_item(subject.variant) }
        let(:supplier_1) { create :supplier }
        let(:supplier_2) { create :supplier }
        let(:si1) {
          shipment.stock_location.stock_items.create( variant: subject.variant, supplier: supplier_1)
        }
        let(:si2) {
          shipment.stock_location.stock_items.create( variant: subject.variant, supplier: supplier_2)
        }

        before do
          si1.set_count_on_hand(3)
          si2.set_count_on_hand(2)
        end

        it 'should create stock_movements' do
          # We want to make sure that the right stock is decremented
          original_stock_item_count = stock_item.count_on_hand

          stock_items = shipment.stock_location.stock_items.where(variant: subject.variant)

          subject.send(:add_to_shipment, shipment, 5).should == 5

          stock_items = shipment.stock_location.stock_items.where(variant: subject.variant)
          expect(stock_item.reload.count_on_hand).to eq original_stock_item_count
          expect(si1.reload.count_on_hand).to eq 0
          expect(si2.reload.count_on_hand).to eq 0

          # check the stock movements
          movement = si1.stock_movements.last
          movement.originator.should == shipment
          movement.quantity.should == -3

          movement = si2.stock_movements.last
          movement.originator.should == shipment
          movement.quantity.should == -2
        end

        it 'should create stock_movements when some are backordered' do

          # We want to make sure that the right stock is decremented
          original_stock_item_count = stock_item.count_on_hand

          stock_items = shipment.stock_location.stock_items.where(variant: subject.variant)

          subject.send(:add_to_shipment, shipment, 7).should == 7

          stock_items = shipment.stock_location.stock_items.where(variant: subject.variant)
          expect(stock_item.reload.count_on_hand).to eq original_stock_item_count - 2
          expect(si1.reload.count_on_hand).to eq 0
          expect(si2.reload.count_on_hand).to eq 0

          # check the stock movements
          movement = stock_item.stock_movements.last
          movement.quantity.should == -2

          movement = si1.stock_movements.last
          movement.quantity.should == -3

          movement = si2.stock_movements.last
          movement.quantity.should == -2
        end


      end

    end

    context "#determine_target_shipment" do
      let(:stock_location) { create :stock_location }
      let(:variant) { line_item.variant }

      before do
        subject.verify

        order.shipments.create(:stock_location_id => stock_location.id, :cost => 5)

        shipped = order.shipments.create(:stock_location_id => order.shipments.first.stock_location.id, :cost => 10)
        shipped.update_column(:state, 'shipped')
      end

      it 'should select first non-shipped shipment that already contains given variant' do
        shipment = subject.send(:determine_target_shipment)
        shipment.shipped?.should be_false
        shipment.inventory_units_for(variant).should_not be_empty

        variant.stock_location_ids.include?(shipment.stock_location_id).should be_true
      end

      context "when no shipments already contain this varint" do
        before do
          subject.line_item.reload
          subject.inventory_units.destroy_all
        end

        it 'selects first non-shipped shipment that leaves from same stock_location' do
          shipment = subject.send(:determine_target_shipment)
          shipment.reload
          shipment.shipped?.should be_false
          shipment.inventory_units_for(variant).should be_empty
          variant.stock_location_ids.include?(shipment.stock_location_id).should be_true
        end
      end
    end

    context 'when order has too many inventory units' do
      before do
        line_item.quantity = 3
        line_item.save!

        line_item.update_column(:quantity, 2)
        subject.line_item.reload
      end

      it 'should be a messed up order' do
        order.shipments.first.inventory_units_for(line_item.variant).size.should == 3
        line_item.quantity.should == 2
      end

      it 'should decrease the number of inventory units' do
        subject.verify
        expect(subject.inventory_units.count).to eq 2
      end

      context '#remove_from_shipment' do
        let(:shipment) { order.shipments.first }
        let(:variant) { subject.variant }

        context "order is not completed" do
          before { order.stub complete?: false }

          it "doesn't restock items" do
            shipment.stock_location.should_not_receive(:restock)
            subject.send(:remove_from_shipment, shipment, 1).should == 1
          end
        end

        context "order is complete" do
          before { order.stub complete?: true }

          it "doesn't restock items" do
            shipment.stock_location.should_receive(:restock)
            subject.send(:remove_from_shipment, shipment, 1).should == 1
          end
        end

        it 'should create stock_movement' do
          subject.send(:remove_from_shipment, shipment, 1).should == 1

          stock_item = shipment.stock_location.stock_item(variant)
          movement = stock_item.stock_movements.last
          # movement.originator.should == shipment
          movement.quantity.should == 1
        end

        it 'should destroy backordered units first' do
          shipment.stub(inventory_units_for_item: [
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered', :supplier => nil),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered', :supplier => nil)
          ])

          shipment.inventory_units_for_item[0].should_receive(:destroy)
          shipment.inventory_units_for_item[1].should_not_receive(:destroy)
          shipment.inventory_units_for_item[2].should_receive(:destroy)

          subject.send(:remove_from_shipment, shipment, 2).should == 2
        end

        it 'should destroy unshipped units first' do
          shipment.stub(inventory_units_for_item: [
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped', :supplier => nil),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil)
          ])

          shipment.inventory_units_for_item[0].should_not_receive(:destroy)
          shipment.inventory_units_for_item[1].should_receive(:destroy)

          subject.send(:remove_from_shipment, shipment, 1).should == 1
        end

        it 'only attempts to destroy as many units as are eligible, and return amount destroyed' do
          shipment.stub(inventory_units_for_item: [
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped', :supplier => nil),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil)
          ])

          shipment.inventory_units_for_item[0].should_not_receive(:destroy)
          shipment.inventory_units_for_item[1].should_receive(:destroy)

          subject.send(:remove_from_shipment, shipment, 1).should == 1
        end

        context "inventory units state with suppliers" do
          let(:supplier_1) { create :supplier }
          let(:supplier_2) { create :supplier }
          before do
            shipment.inventory_units.destroy_all
            FillStatusItem = Struct.new(:supplier, :count)
            # order.stub complete?: true
          end

          it 'restocks items back to the correct supplier' do
            shipment.stock_location.should_receive(:restock).with(variant, 1, shipment, nil )
            shipment.stock_location.should_receive(:restock).with(variant, 3, shipment, supplier_1 )
            shipment.stock_location.should_receive(:restock).with(variant, 1, shipment, supplier_2 )

            shipment.stub(inventory_units_for_item: [
              mock_model(Spree::InventoryUnit, :variant_id => variant.id, supplier: nil, :state => 'on_hand'),
              mock_model(Spree::InventoryUnit, :variant_id => variant.id, supplier: supplier_1, :state => 'backordered'),
              mock_model(Spree::InventoryUnit, :variant_id => variant.id, supplier: supplier_1, :state => 'on_hand'),
              mock_model(Spree::InventoryUnit, :variant_id => variant.id, supplier: supplier_1, :state => 'backordered'),
              mock_model(Spree::InventoryUnit, :variant_id => variant.id, supplier: supplier_2, :state => 'on_hand'),
            ])

            subject.send(:remove_from_shipment, shipment, 5).should == 5
          end
        end

        it 'should destroy self if not inventory units remain' do
          shipment.inventory_units.stub(:count => 0)
          shipment.should_receive(:destroy)

          subject.send(:remove_from_shipment, shipment, 1).should == 1
        end

        context "inventory unit line item and variant points to different products" do
          let(:different_line_item) { create(:line_item) }

          let!(:different_inventory) do
            shipment.set_up_inventory("on_hand", variant, order, different_line_item)
          end

          context "completed order" do
            before { order.touch :completed_at }

            it "removes only units that match both line item and variant" do
              subject.send(:remove_from_shipment, shipment, shipment.inventory_units.count)
              expect(different_inventory.reload).to be_persisted
            end
          end
        end
      end
    end

    ## from Spree Product Assembly

    describe "Inventory units for assemblies" do
      let(:order) { create(:order_with_line_items, line_items_count: 1) }
      let(:line_item) { order.line_items.first }
      let(:bundle) { line_item.product }
      let(:parts) { (1..3).map { create(:part, line_item: line_item) } }
      let!(:container_part) { create(:part, quantity: 2, line_item: line_item, container: true) }

      before do
        parts.first.update_column(:quantity, 3)
        line_item.update_column(:quantity, 3)
        order.reload.create_proposed_shipments
        order.finalize!
        # subject.verify
      end

      context "inventory units count" do
        it "calculates the proper value for all physical parts (without the line item itself or containers)" do
          expected_units_count = line_item.quantity * parts.to_a.sum(&:quantity)
          expect(subject.inventory_units.count).to eql(expected_units_count)
        end
      end

      context "inventory units line_item_part_id" do

        it "should be nil for non assembly items" do
          expected_units_count = line_item.quantity * parts.to_a.sum(&:quantity)
          units_1 = (subject.inventory_units).select { |u| u.line_item_part == parts[0] }
          units_2 = (subject.inventory_units).select { |u| u.line_item_part == parts[1] }
          units_3 = (subject.inventory_units).select { |u| u.line_item_part == parts[2] }
          units_4 = (subject.inventory_units).select { |u| u.line_item_part.nil? }
          expect(units_1.size).to eq 9
          expect(units_2.size).to eq 3
          expect(units_3.size).to eq 3
          expect(units_4.size).to eq 0
        end

      end

      context "verify line item units" do
        let!(:original_units_count) { subject.inventory_units.count }

        context "quantity increases" do
          before { subject.line_item.quantity += 1 }

          it "inserts new inventory units for every bundle part with disregard to the line item itself" do
            expected_units_count = original_units_count + parts.to_a.sum(&:quantity)
            subject.verify
            expect(OrderInventory.new(line_item.order, line_item.reload).inventory_units.count).to eql(expected_units_count)
          end
        end

        context "quantity decreases" do
          before { subject.line_item.quantity -= 1 }

          it "remove inventory units for every bundle part with disregard to the line item itself" do
            expected_units_count = original_units_count - parts.to_a.sum(&:quantity)
            subject.verify

            # needs to reload so that inventory units are fetched from updates order.shipments
            updated_units_count = OrderInventory.new(line_item.order.reload, line_item.reload).inventory_units.count
            expect(updated_units_count).to eql(expected_units_count)
          end
        end

        context "quantity decreases to 0" do
          before { subject.line_item.quantity = 0 }

          it "remove inventory all units for every bundle part" do
            expected_units_count = original_units_count - parts.to_a.sum(&:quantity)
            subject.verify

            # needs to reload so that inventory units are fetched from updates order.shipments
            updated_units_count = OrderInventory.new(line_item.order.reload, line_item.reload).inventory_units.count
            expect(updated_units_count).to eql(0)
          end
        end

      end
    end

    context "same variant within bundle and as regular product" do
      let(:order) { Spree::Order.create }

      subject { Spree::OrderInventory.new(order, order.line_items.first) }
      let(:contents) { Spree::OrderContents.new(order) }
      let(:guitar) { create(:variant) }
      let(:bass) { create(:variant) }

      let(:bundle) { create(:product) }
      let(:line_item_parts) {[
        OpenStruct.new(
                       variant_id: guitar.id,
                       quantity:   1,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      ),
        OpenStruct.new(
                       variant_id: bass.id,
                       quantity:   1,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}

      let!(:bundle_item) { contents.add(bundle.master, 5, nil, parts: line_item_parts) }
      let!(:guitar_item) { contents.add(guitar, 3) }

      let!(:shipment) { order.create_proposed_shipments.first }

      context "completed order" do
        before { order.touch :completed_at }

        it "removes only units associated with provided line item" do
          expect {
            subject.send(:remove_from_shipment, shipment, 5)
          }.not_to change { guitar_item.inventory_units.count }
        end
      end
    end

  end
end
