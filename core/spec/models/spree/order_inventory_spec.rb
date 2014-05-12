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
        before { order.stub completed?: false }

        it "doesn't unstock items" do
          shipment.stock_location.should_not_receive(:unstock)
          subject.send(:add_to_shipment, shipment, 5).should == 5
        end
      end

      context "inventory units state" do
        before { shipment.inventory_units.destroy_all }

        it 'sets inventory_units state as per stock location availability' do
          shipment.stock_location.should_receive(:fill_status).with(subject.variant, 5).and_return([3, 2])

          subject.send(:add_to_shipment, shipment, 5).should == 5

          units = shipment.inventory_units_for(subject.variant).group_by(&:state)
          units['backordered'].size.should == 2
          units['on_hand'].size.should == 3
        end
      end

      context "store doesnt track inventory" do
        let(:variant) { create(:variant) }

        before { Spree::Config.track_inventory_levels = false }

        it "creates only on hand inventory units" do
          variant.stock_items.destroy_all

          # The before_save callback in LineItem would verify inventory
          line_item = order.contents.add variant, 1, nil, shipment

          units = shipment.inventory_units_for(line_item.variant)
          expect(units.count).to eq 1
          expect(units.first).to be_on_hand
        end
      end

      context "variant doesnt track inventory" do
        let(:variant) { create(:variant) }
        before { variant.track_inventory = false }

        it "creates only on hand inventory units" do
          variant.stock_items.destroy_all

          line_item = order.contents.add variant, 1
          subject.verify(shipment)

          units = shipment.inventory_units_for(line_item.variant)
          expect(units.count).to eq 1
          expect(units.first).to be_on_hand
        end
      end

      it 'should create stock_movement' do
        subject.send(:add_to_shipment, shipment, 5).should == 5

        stock_item = shipment.stock_location.stock_item(subject.variant)
        movement = stock_item.stock_movements.last
        # movement.originator.should == shipment
        movement.quantity.should == -5
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
          before { order.stub completed?: false }

          it "doesn't restock items" do
            shipment.stock_location.should_not_receive(:restock)
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
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered'),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand'),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered')
          ])

          shipment.inventory_units_for_item[0].should_receive(:destroy)
          shipment.inventory_units_for_item[1].should_not_receive(:destroy)
          shipment.inventory_units_for_item[2].should_receive(:destroy)

          subject.send(:remove_from_shipment, shipment, 2).should == 2
        end

        it 'should destroy unshipped units first' do
          shipment.stub(inventory_units_for_item: [
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped'),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand')
          ])

          shipment.inventory_units_for_item[0].should_not_receive(:destroy)
          shipment.inventory_units_for_item[1].should_receive(:destroy)

          subject.send(:remove_from_shipment, shipment, 1).should == 1
        end

        it 'only attempts to destroy as many units as are eligible, and return amount destroyed' do
          shipment.stub(inventory_units_for_item: [
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped'),
            mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand')
          ])

          shipment.inventory_units_for_item[0].should_not_receive(:destroy)
          shipment.inventory_units_for_item[1].should_receive(:destroy)

          subject.send(:remove_from_shipment, shipment, 1).should == 1
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

      before do
        parts.first.update_column(:quantity, 3)

        line_item.update_column(:quantity, 3)
        order.reload.create_proposed_shipments
        order.finalize!
        # subject.verify
      end

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
            expected_units_count = original_units_count + parts.to_a.sum(&:quantity) + 1 # since we increased the line item quantity by one
            subject.verify
            expect(OrderInventory.new(line_item.order, line_item.reload).inventory_units.count).to eql(expected_units_count)
          end
        end

        context "quantity decreases" do
          before { subject.line_item.quantity -= 1 }

          it "remove inventory units for every bundle part" do # since we decreased the line item quantity by one
            expected_units_count = original_units_count - parts.to_a.sum(&:quantity) - 1
            subject.verify

            # needs to reload so that inventory units are fetched from updates order.shipments
            updated_units_count = OrderInventory.new(line_item.order.reload, line_item.reload).inventory_units.count
            expect(updated_units_count).to eql(expected_units_count)
          end
        end

        context "quantity decreases to 0" do
          before { subject.line_item.quantity = 0 }

          it "remove inventory all units for every bundle part" do # since we decreased the line item quantity by one
            expected_units_count = original_units_count - parts.to_a.sum(&:quantity) - 1
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

      let!(:bundle_item) { contents.add(bundle.master, 5, nil, nil, line_item_parts) }
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
