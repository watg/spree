require 'spec_helper'

describe Spree::OrderInventory, :type => :model do
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
      let!(:variant) { subject.variant }
      let(:inventory_unit) { mock_model(Spree::InventoryUnit)}
      let(:allocator) { double(Spree::Stock::Allocator) }

      before do
        allow(Spree::Stock::Allocator).to receive(:new).and_return(allocator)
        allow(allocator).to receive(:unstock)
      end

<<<<<<< HEAD

    context "order can not be shipped" do
      before { allow(order).to receive_messages can_ship?: false }

      it "doesn't unstock items" do
        expect_any_instance_of(Spree::Stock::Allocator).to_not receive(:unstock)
        expect(subject.send(:add_to_shipment, shipment, 5)).to eq(5)
=======
      context "order can not have stock allocated to it" do
        before { order.stub can_allocate_stock?: false }

        it "doesn't unstock items" do
          expect_any_instance_of(Spree::Stock::Allocator).to_not receive(:unstock)
          subject.send(:add_to_shipment, shipment, 5).should == 5
        end
      end

      context "order can have stock allocated to it" do
        before do
          order.stub can_allocate_stock?: true
          allow(shipment).to receive(:set_up_inventory).and_return(inventory_unit)
          shipment.stub(:set_up_inventory).and_return(inventory_unit)
        end

        it "unstocks items" do
          shipment.stock_location.should_receive(:fill_status).with(subject.variant, 2).and_return([2,0, 0])
          subject.send(:add_to_shipment, shipment, 2).should == 2
          expect(allocator).to have_received(:unstock).with(variant, [inventory_unit, inventory_unit])
        end
>>>>>>> master
      end
    end

    context "order can be shipped" do
      before do
        allow(order).to receive_messages can_ship?: true
        allow(shipment).to receive(:set_up_inventory).and_return(inventory_unit)
        allow(shipment).to receive(:set_up_inventory).and_return(inventory_unit)
      end

      it "unstocks items" do
        expect(shipment.stock_location).to receive(:fill_status).with(subject.variant, 2).and_return([2,0, 0])
        expect(subject.send(:add_to_shipment, shipment, 2)).to eq(2)
        expect(allocator ).to have_received(:unstock).with(variant, [inventory_unit, inventory_unit])
      end
    end

    context "inventory units line_item_part_id" do

      before do
        rtn = [3,0,0]
        expect(shipment.stock_location).to receive(:fill_status).with(subject.variant, 5).and_return(rtn)
      end


      it "should be nil for non assembly items" do
        expect(subject.send(:add_to_shipment, shipment, 5)).to eq(5)
        units = shipment.inventory_units_for(subject.variant).select { |u| !u.line_item_part.nil? }
        expect(units.size).to eq 0
      end

    end

    context "inventory units state" do
      before do
        shipment.inventory_units.destroy_all
      end

      it 'sets inventory_units state as per stock location availability' do
        rtn = [3, 2, 1]
        expect(shipment.stock_location).to receive(:fill_status).with(subject.variant, 6).and_return(rtn)

        expect(subject.send(:add_to_shipment, shipment, 6)).to eq(6)

        units = shipment.inventory_units_for(subject.variant).group_by(&:state)
        expect(units['backordered'].size).to eq(2)
        expect(units['on_hand'].size).to eq(3)
        expect(units['awaiting_feed'].size).to eq(1)
      end
    end

    context "store doesnt track inventory" do
      let(:variant) { create(:variant) }

      before { Spree::Config.track_inventory_levels = false }

      it "creates only on hand inventory units" do
        variant.stock_items.destroy_all

        # The before_save callback in LineItem would verify inventory
        line_item = order.contents.add( variant, 1, shipment: shipment )

        units = shipment.inventory_units_for(line_item.variant)
        expect(units.count).to eq 1
        expect(units.first).to be_on_hand
      end
    end

    context "variant doesnt track inventory" do
      let(:variant) { create(:variant) }

      before do
        variant.track_inventory = false
      end

      it "creates only on hand inventory units" do
        line_item = order.contents.add( variant, 1, {} )
        subject.verify(shipment)

        units = shipment.inventory_units_for(line_item.variant)
        expect(units.count).to eq 1
        expect(units.first).to be_on_hand
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
      expect(shipment.shipped?).to be false
      expect(shipment.inventory_units_for(variant)).not_to be_empty

      expect(variant.stock_location_ids.include?(shipment.stock_location_id)).to be true
    end

    context "when no shipments already contain this varint" do
      before do
        subject.line_item.reload
        subject.inventory_units.destroy_all
      end

      it 'selects first non-shipped shipment that leaves from same stock_location' do
        shipment = subject.send(:determine_target_shipment)
        shipment.reload
        expect(shipment.shipped?).to be false
        expect(shipment.inventory_units_for(variant)).to be_empty
        expect(variant.stock_location_ids.include?(shipment.stock_location_id)).to be true
      end
    end
  end

<<<<<<< HEAD
  context 'when order has too many inventory units' do
    before do
      line_item.quantity = 3
      line_item.save!

      line_item.update_column(:quantity, 2)
      subject.line_item.reload
    end

    it 'should be a messed up order' do
      expect(order.shipments.first.inventory_units_for(line_item.variant).size).to eq(3)
      expect(line_item.quantity).to eq(2)
    end

    it 'should decrease the number of inventory units' do
      subject.verify
      expect(subject.inventory_units.count).to eq 2
    end
  end

  context '#remove_from_shipment' do
    let(:shipment) { order.shipments.first }
    let(:variant) { subject.variant }

    context "order can not be shippped" do
      before { allow(order).to receive_messages can_ship?: false }

      it "doesn't restock items" do
        expect_any_instance_of(Spree::Stock::Allocator).to_not receive(:restock)
        expect(subject.send(:remove_from_shipment, shipment, 1)).to eq(1)
      end
    end

    context "order can be shipped" do
      let!(:mock_inventory_unit) { mock_model(Spree::InventoryUnit)}

      before do
        allow(order).to receive_messages can_ship?: true
        allow(shipment).to receive(:inventory_units_for_item).and_return( [ mock_inventory_unit ] )
      end

      it "doesn't restock items" do
        expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [ mock_inventory_unit])
        expect(subject.send(:remove_from_shipment, shipment, 1)).to eq(1)
      end
    end

    it 'should create stock_movement' do
      expect(subject.send(:remove_from_shipment, shipment, 1)).to eq(1)
      stock_item = shipment.stock_location.stock_item(variant)
      movement = stock_item.stock_movements.last
      # Originator will be missing as the shipment will be deteleted
      # as there will be no inventory units
      #expect(movement.originator).to eq(shipment)
      expect(movement.quantity).to eq(1)
    end

    it 'should destroy backordered units first' do

      backordered_1 = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered', :supplier => nil)
      backordered_2 = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered', :supplier => nil)
      allow(shipment).to receive_messages(inventory_units_for_item: [
        backordered_1,
        mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil),
        backordered_2,
      ])

      expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [backordered_1, backordered_2])
      expect(shipment.inventory_units_for_item[0]).to receive(:destroy)
      expect(shipment.inventory_units_for_item[1]).not_to receive(:destroy)
      expect(shipment.inventory_units_for_item[2]).to receive(:destroy)

      expect(subject.send(:remove_from_shipment, shipment, 2)).to eq(2)
    end

    it 'should destroy unshipped units first' do
      on_hand = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil)
      allow(shipment).to receive_messages(inventory_units_for_item: [
        mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped', :supplier => nil),
        on_hand
      ])

      expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [on_hand])
      expect(shipment.inventory_units_for_item[0]).not_to receive(:destroy)
      expect(shipment.inventory_units_for_item[1]).to receive(:destroy)

      expect(subject.send(:remove_from_shipment, shipment, 1)).to eq(1)
    end

    it 'only attempts to destroy as many units as are eligible, and return amount destroyed' do
      on_hand = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil)

      allow(shipment).to receive_messages(inventory_units_for_item: [
        mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped', :supplier => nil),
        on_hand
      ])

      expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [on_hand])
      expect(shipment.inventory_units_for_item[0]).not_to receive(:destroy)
      expect(shipment.inventory_units_for_item[1]).to receive(:destroy)

      expect(subject.send(:remove_from_shipment, shipment, 1)).to eq(1)
    end

    it 'should destroy self if not inventory units remain' do
      allow(shipment.inventory_units).to receive_messages(:count => 0)
      expect(shipment).to receive(:destroy)

      expect(subject.send(:remove_from_shipment, shipment, 1)).to eq(1)
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
=======
      it 'should decrease the number of inventory units' do
        subject.verify
        expect(subject.inventory_units.count).to eq 2
      end
    end

    context '#remove_from_shipment' do
      let(:shipment) { order.shipments.first }
      let(:variant) { subject.variant }

      context "order can not have stock allocated to it" do
        before { order.stub can_allocate_stock?: false }

        it "doesn't restock items" do
          expect_any_instance_of(Spree::Stock::Allocator).to_not receive(:restock)
          subject.send(:remove_from_shipment, shipment, 1).should == 1
        end
      end

      context "order can have stock allocated to it" do
        let!(:mock_inventory_unit) { mock_model(Spree::InventoryUnit)}

        before do
          order.stub can_allocate_stock?: true
          allow(shipment).to receive(:inventory_units_for_item).and_return( [ mock_inventory_unit ] )
        end

        it "doesn't restock items" do
          expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [ mock_inventory_unit])
          subject.send(:remove_from_shipment, shipment, 1).should == 1
        end
      end

      it 'should create stock_movement' do
        subject.send(:remove_from_shipment, shipment, 1).should == 1
        stock_item = shipment.stock_location.stock_item(variant)
        movement = stock_item.stock_movements.last
        movement.originator.should == shipment
        movement.quantity.should == 1
      end

      it 'should destroy backordered units first' do

        backordered_1 = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered', :supplier => nil)
        backordered_2 = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'backordered', :supplier => nil)
        shipment.stub(inventory_units_for_item: [
          backordered_1,
          mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil),
          backordered_2,
        ])

        expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [backordered_1, backordered_2])
        shipment.inventory_units_for_item[0].should_receive(:destroy)
        shipment.inventory_units_for_item[1].should_not_receive(:destroy)
        shipment.inventory_units_for_item[2].should_receive(:destroy)

        subject.send(:remove_from_shipment, shipment, 2).should == 2
      end

      it 'should destroy unshipped units first' do
        on_hand = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil)
        shipment.stub(inventory_units_for_item: [
          mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped', :supplier => nil),
          on_hand
        ])

        expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [on_hand])
        shipment.inventory_units_for_item[0].should_not_receive(:destroy)
        shipment.inventory_units_for_item[1].should_receive(:destroy)

        subject.send(:remove_from_shipment, shipment, 1).should == 1
      end

      it 'only attempts to destroy as many units as are eligible, and return amount destroyed' do
        on_hand = mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'on_hand', :supplier => nil)

        shipment.stub(inventory_units_for_item: [
          mock_model(Spree::InventoryUnit, :variant_id => variant.id, :state => 'shipped', :supplier => nil),
          on_hand
        ])

        expect_any_instance_of(Spree::Stock::Allocator).to receive(:restock).with(variant, [on_hand])
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
>>>>>>> master
        end
      end
    end
  end

  context "Assemblies" do
    let!(:order) { create(:order) }
    let!(:line_item_1) { create(:line_item, order: order ) }
    let!(:line_item_2) { create(:line_item, order: order ) }

    let!(:part_variant) { create(:base_variant) }

    let!(:stock_location) { part_variant.stock_locations.first }

    let!(:part_for_line_item_1) { create(:part, line_item: line_item_1, variant: part_variant) }
    let!(:part_for_line_item_2) { create(:part, line_item: line_item_2, variant: part_variant) }

    let!(:supplier_1) { create(:supplier) }
    let!(:supplier_2) { create(:supplier) }

    let!(:shipment) { create(:base_shipment, order: order, stock_location: stock_location) }
    let!(:si_1) { create(:stock_item, variant: part_variant, supplier: supplier_1, stock_location: stock_location, backorderable: false) }
    let!(:si_2) { create(:stock_item, variant: part_variant, supplier: supplier_2, stock_location: stock_location, backorderable: false) }

    before do
      si_1.set_count_on_hand(1)
      si_2.set_count_on_hand(1)
      line_item_1.reload
      line_item_2.reload
      order.update_column(:state, 'complete')
      order.update_column(:completed_at, '2013-02-01')
    end

    it "removes stock from both suppliers when there is not enough stock from one" do
      expect(line_item_1.inventory_units.size).to eq 0
      expect(line_item_2.inventory_units.size).to eq 0
      Spree::OrderInventory.new(order, line_item_1).verify
      Spree::OrderInventory.new(order, line_item_2).verify
      expect(line_item_1.reload.inventory_units.size).to eq 1
      expect(line_item_2.reload.inventory_units.size).to eq 1

      expect(line_item_1.inventory_units.first.supplier).to_not eq line_item_2.inventory_units.first.supplier
      expect([supplier_1, supplier_2]).to include(line_item_1.inventory_units.first.supplier)
      expect([supplier_1, supplier_2]).to include(line_item_2.inventory_units.first.supplier)

      expect(si_1.reload.count_on_hand).to eq 0
      expect(si_2.reload.count_on_hand).to eq 0
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
          expect(Spree::OrderInventory.new(line_item.order, line_item.reload).inventory_units.count).to eql(expected_units_count)
        end
      end

      context "quantity decreases" do
        before { subject.line_item.quantity -= 1 }

        it "remove inventory units for every bundle part with disregard to the line item itself" do
          expected_units_count = original_units_count - parts.to_a.sum(&:quantity)
          subject.verify

          # needs to reload so that inventory units are fetched from updates order.shipments
          updated_units_count = Spree::OrderInventory.new(line_item.order.reload, line_item.reload).inventory_units.count
          expect(updated_units_count).to eql(expected_units_count)
        end
      end

      context "quantity decreases to 0" do
        before { subject.line_item.quantity = 0 }

        it "remove inventory all units for every bundle part" do
          expected_units_count = original_units_count - parts.to_a.sum(&:quantity)
          subject.verify

          # needs to reload so that inventory units are fetched from updates order.shipments
          updated_units_count = Spree::OrderInventory.new(line_item.order.reload, line_item.reload).inventory_units.count
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
      Spree::LineItemPart.new(
        variant_id: guitar.id,
        quantity:   1,
        optional:   true,
        price:      5,
        currency:   'GBP'
      ),
      Spree::LineItemPart.new(
        variant_id: bass.id,
        quantity:   1,
        optional:   true,
        price:      5,
        currency:   'GBP'
      )
    ]}

    let!(:bundle_item) { contents.add(bundle.master, 5, parts: line_item_parts) }
    let!(:guitar_item) { contents.add(guitar, 3, {}) }

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
