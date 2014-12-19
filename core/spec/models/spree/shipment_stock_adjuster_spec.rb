require 'spec_helper'

describe Spree::ShipmentStockAdjuster do

  let(:stock_location) { build_stubbed(:stock_location) }
  let(:shipment) { mock_model(Spree::Shipment, stock_location: stock_location) }
  let(:supplier) { mock_model(Spree::Supplier, id: 22) }
  let(:variant) { mock_model(Spree::Variant) }
  let(:order) { Spree::Order.new }

  let(:inventory_units) { build_list(:inventory_unit, 3, line_item: nil, supplier: supplier, variant: variant, state: 'on_hand') }
  subject(:adjuster) { described_class.new(shipment)  }

  context "restock" do

    it "restocks all the on_hand and backordered inventory_units" do
      inventory_units.last.state = 'backordered'
      expect(stock_location).to receive(:restock).with(variant, 3, shipment, supplier)
      inventory_units.stub(:update_all)
      subject.restock(variant, inventory_units)
    end

    it "does not restock the awaiting_feed inventory_units" do
      inventory_units.last.state = 'awaiting_feed'
      expect(stock_location).to receive(:restock).with(variant, 2, shipment, supplier)
      inventory_units.stub(:update_all)
      subject.restock(variant, inventory_units)
    end

    it "sets inventory_units` supplier to nil and their pending state to true" do
      units = []
      units << Spree::InventoryUnit.create(order: order, pending: false, supplier_id: 1, variant: variant)
      units << Spree::InventoryUnit.create(order: order, state: 'backordered', pending: false, supplier_id: 2, variant: variant)
      units << Spree::InventoryUnit.create(order: order, state: 'awaiting_feed', pending: false, supplier_id: 3, variant: variant)
      stock_location.stub(:restock)

      subject.restock(variant, units)
      expect(order.inventory_units.pluck(:supplier_id)).to eq [nil, nil, nil]
      expect(order.inventory_units.pluck(:pending)).to eq [true, true, true]
    end

  end

  context "unstock" do
    let(:supplier) { nil } # create inventory units without suppliers
    let(:iu_states) { 3.times.map { 'on_hand'} }
    let(:backorderable) { true }
    let(:count_on_hand) { 2 }
    let(:stock_items) {  2.times.map { mock_model(Spree::StockItem, count_on_hand: count_on_hand, backorderable?: backorderable) }  }
    let(:feeder_stock_items) { [] }

    before do
      inventory_units.each_with_index do |iu, idx|
        allow(iu).to receive(:state).and_return(iu_states[idx])
      end
      allow(adjuster).to receive(:available_items).and_return(stock_items)
      allow(adjuster).to receive(:feeder_stock_items).with(variant).and_return(feeder_stock_items)
    end

    context "when all stock is on hand" do
      it "unstocks the items" do
        expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.first(2)).once
        expect(adjuster).to receive(:unstock_stock_item).with(stock_items[1], inventory_units.last(1)).once
        adjuster.unstock(variant, inventory_units)
      end
    end

    context "when only partial stock is on hand" do
      context "and the stock is backordered" do
        let(:iu_states) { 3.times.map { 'backordered' } }

        it "assigns stock which is backordered" do
          expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units).once
          adjuster.unstock(variant, inventory_units)
        end

        context "but the stock item does not allow backordering" do
          let(:backorderable) { false }

          context "but it does have count on hand" do
            it "allocates stock from on hand" do
              expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.first(2)).once
              expect(adjuster).to receive(:unstock_stock_item).with(stock_items[1], inventory_units.last(1)).once
              adjuster.unstock(variant, inventory_units)
            end

            it "changes the inventory unit state to on_hand" do
              allow(adjuster).to receive(:unstock_stock_item)
              inventory_units.each do |iu|
                expect(iu).to receive(:state=).with(:on_hand).ordered
                expect(iu).to receive(:save).ordered
              end
              adjuster.unstock(variant, inventory_units)
            end
          end

          context "but it doesn't have count on hand but it is in a feeder" do
            let(:count_on_hand) { 0 }
            let(:feeder_stock_items) { [mock_model(Spree::StockItem, count_on_hand: 3)] }

            it "changes the inventory unit state to awaiting feed" do
              inventory_units.each do |iu|
                expect(iu).to receive(:state=).with(:awaiting_feed).ordered
                expect(iu).to receive(:save).ordered
              end
              adjuster.unstock(variant, inventory_units)
            end
          end

          context "and there is no stock anywhere" do
            let(:count_on_hand) { 0 }
            it "allocates stock from any matching stock item" do
              expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units).once
              adjuster.unstock(variant, inventory_units)
            end

            it "changes the inventory unit state to on_hand" do
              allow(adjuster).to receive(:unstock_stock_item)
              inventory_units.each do |iu|
                expect(iu).to receive(:state=).with(:on_hand).ordered
                expect(iu).to receive(:save).ordered
              end
              adjuster.unstock(variant, inventory_units)
            end
          end
        end
      end

      context "and somehow there is no stock available" do
        let(:count_on_hand) { 0 }

        context "with stock available in a feeder location" do
          let(:feeder_stock_items) { [mock_model(Spree::StockItem, count_on_hand: 3)] }

          it "changes the inventory unit state to awaiting feed" do
            inventory_units.each do |iu|
              expect(iu).to receive(:state=).with(:awaiting_feed).ordered
              expect(iu).to receive(:save).ordered
            end
            adjuster.unstock(variant, inventory_units)
          end
        end

        context "with backorderable stock available" do
          let(:backorderable) { true }

          it "allocates the stock from backorderable inventory units" do
            expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units).once
            adjuster.unstock(variant, inventory_units)
          end

          it "changes the inventory unit state to backordered" do
              allow(adjuster).to receive(:unstock_stock_item)
              inventory_units.each do |iu|
                expect(iu).to receive(:state=).with(:backordered).ordered
                expect(iu).to receive(:save).ordered
              end
              adjuster.unstock(variant, inventory_units)
          end
        end

        context "with no stock available in feeders either" do
          let(:count_on_hand) { 0 }

          it "allocates stock from any matching stock item" do
            expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units).once
            adjuster.unstock(variant, inventory_units)
          end
        end
      end
    end

    context "when an inventory unit awaiting feed" do
      let(:iu_states) { ["on_hand", "backorderable", "awaiting_feed"] }

      it "does not unstock items awaiting_feed" do
        expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.slice(0,1)).once
        expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.slice(1,1)).once
        adjuster.unstock(variant, inventory_units)
      end
    end
  end

  context "available_items" do

    let!(:stock_location) { create(:base_stock_location) }
    let(:variant) { create(:base_variant) }
    let(:stock_item_1) { create(:stock_item, stock_location: stock_location, count_on_hand: 2, backorderable: true, variant: variant, last_unstocked_at: '2012-01-01') }
    let(:stock_item_2) { create(:stock_item, stock_location: stock_location, count_on_hand: 2, backorderable: true, variant: variant, last_unstocked_at: '2012-02-01') }


    it "returns stock in time order of last_updated_at" do
      expect(subject.send(:available_items, variant)).to eq [ stock_item_1, stock_item_2 ]
    end

    context "last_unstocked_at is nil " do

      before do
        stock_item_2.last_unstocked_at = nil
        stock_item_2.save
      end

      it "returns puts nils first for last_updated_at" do
        expect(subject.send(:available_items, variant)).to eq [ stock_item_2, stock_item_1 ]
      end

    end

  end

  context "unstock_stock_item" do
    let!(:stock_item) { Spree::StockItem.create!(backorderable: true, supplier: supplier, variant: variant, stock_location: stock_location) }
    let(:units) { [] }

    before do
      allow(variant).to receive(:touch)
      allow(stock_item).to receive(:trigger_suite_tab_cache_rebuilder)
      stock_item.update_column(:count_on_hand, 2)
      units << Spree::InventoryUnit.create(order: order, pending: true, supplier_id: nil)
      units << Spree::InventoryUnit.create(order: order, pending: true, supplier_id: nil)
    end

    it "sets inventory unit attributes" do
      # Creates a stock movement
      stock_movements = double('StockMovement')
      expect(stock_movements).to receive(:create!).once.with(quantity: -2, originator: shipment)
      expect(stock_item).to receive(:stock_movements).once.and_return(stock_movements)

      subject.send(:unstock_stock_item, stock_item, units)

      # Updates the supplier and sets the state of the units back to pending false
      expect(order.inventory_units.pluck(:supplier_id)).to eq [22, 22] # the ID of the supplier
      expect(order.inventory_units.pluck(:pending)).to eq [false, false]

      # Updates the stock_item last_unstocked_at time
      expect(stock_item.last_unstocked_at).to be_within(1.second).of(Time.now)
    end
  end

end
