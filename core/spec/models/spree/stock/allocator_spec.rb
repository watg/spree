require 'spec_helper'

describe Spree::Stock::Allocator do

  let(:stock_location) { build_stubbed(:stock_location) }
  let(:shipment) { mock_model(Spree::Shipment, stock_location: stock_location) }
  let(:supplier) { mock_model(Spree::Supplier, id: 22) }
  let(:variant) { mock_model(Spree::Variant) }
  let(:order) { Spree::Order.new }

  let(:inventory_units) { build_list(:inventory_unit, 3, line_item: nil, supplier: supplier, variant: variant, state: 'on_hand', pending: false) }
  subject(:adjuster) { described_class.new(shipment)  }

  describe "#restock" do

    it "Calls save on each of the inventory units" do
      allow(stock_location).to receive(:restock)
      inventory_units.each do |iu|
        expect(iu).to receive(:pending=).with(true)
        expect(iu).to receive(:supplier_id=).with(nil)
        expect(iu).to receive(:save)
      end
      subject.restock(variant, inventory_units)
    end

    it "sets inventory_units` supplier to nil and their pending state to true" do
      units = []
      units << Spree::InventoryUnit.create(order: order, pending: false, supplier_id: 1, variant: variant)
      units << Spree::InventoryUnit.create(order: order, state: 'backordered', pending: false, supplier_id: 2, variant: variant)
      units << Spree::InventoryUnit.create(order: order, state: 'awaiting_feed', pending: false, supplier_id: 3, variant: variant)
      expect(stock_location).to receive(:restock)

      subject.restock(variant, units)
      expect(order.inventory_units.pluck(:supplier_id)).to eq [nil, nil, nil]
      expect(order.inventory_units.pluck(:pending)).to eq [true, true, true]
    end

    context "stock_location.restock is called with the correct parameters" do
      before do
        inventory_units.each do |iu|
          allow(iu).to receive(:supplier_id=).with(nil)
          allow(iu).to receive(:pending=).with(true)
          allow(iu).to receive(:save)
        end
      end

      it "restocks on_hand inventory_units" do
        expect(stock_location).to receive(:restock).with(variant, 3, shipment, supplier)
        subject.restock(variant, inventory_units)
      end

      it "does not restock backordered inventory_units" do
        inventory_units.last.state = 'backordered'
        expect(stock_location).to receive(:restock).with(variant, 2, shipment, supplier)
        subject.restock(variant, inventory_units)
      end

      it "does not restock the awaiting_feed inventory_units" do
        inventory_units.last.state = 'awaiting_feed'
        expect(stock_location).to receive(:restock).with(variant, 2, shipment, supplier)
        subject.restock(variant, inventory_units)
      end
    end

    context "with stubbed out #restock" do
      before do
        allow(stock_location).to receive(:restock)
      end

      it "calls #clear_total_on_hand_cache" do
        expect(subject).to receive(:clear_total_on_hand_cache).with(variant)
        subject.restock(variant, inventory_units)
      end
    end
  end

  describe "#unstock" do

    let(:inventory_units) { build_list(:inventory_unit, 3, line_item: nil, supplier: supplier, variant: variant, state: 'on_hand', pending: true) }

    it "calls save on each of the inventory units" do
      expect(subject).to receive(:unstock_on_hand)
      inventory_units.each do |iu|
        expect(iu).to receive(:pending=).with(false)
        expect(iu).to receive(:save)
      end
      subject.unstock(variant, inventory_units)
    end

    it "sets pending state to false" do
      units = []
      units << Spree::InventoryUnit.create(order: order, pending: true, supplier_id: 1, variant: variant)
      units << Spree::InventoryUnit.create(order: order, state: 'backordered', pending: true, supplier_id: 2, variant: variant)
      units << Spree::InventoryUnit.create(order: order, state: 'awaiting_feed', pending: true, supplier_id: 3, variant: variant)
      allow(subject).to receive(:unstock_on_hand)

      subject.unstock(variant, units)
      expect(order.inventory_units.pluck(:pending)).to eq [false, false, false]
    end

    context "unstock_on_hand is called with the correct parameters" do
      before do
        inventory_units.each do |iu|
          allow(iu).to receive(:pending=).with(false)
          allow(iu).to receive(:save)
        end
      end
    
      it "unstocks on_hand inventory_units" do
        expect(subject).to receive(:unstock_on_hand).with(variant, inventory_units )
        subject.unstock(variant, inventory_units)
      end

      it "does not unstock backordered inventory_units" do
        inventory_units.last.state = 'backordered'
        expect(subject).to receive(:unstock_on_hand).with(variant, inventory_units.first(2) )
        subject.unstock(variant, inventory_units)
      end

      it "does not unstock the awaiting_feed inventory_units" do
        inventory_units.last.state = 'awaiting_feed'
        expect(subject).to receive(:unstock_on_hand).with(variant, inventory_units.first(2) )
        subject.unstock(variant, inventory_units)
      end
    end

    context "with stubbed out #unstock_on_hand" do
      before do
        allow(subject).to receive(:unstock_on_hand)
      end

      it "calls #clear_total_on_hand_cache" do
        expect(subject).to receive(:clear_total_on_hand_cache).with(variant)
        subject.unstock(variant, inventory_units)
      end
    end
  end

  describe "#unstock_on_hand" do

    let(:backorderable) { false }
    let(:count_on_hand) { 2 }
    let(:stock_items) {  2.times.map { mock_model(Spree::StockItem, count_on_hand: count_on_hand, backorderable?: backorderable) }  }

    before do
      allow(adjuster).to receive(:available_items).and_return(stock_items)
    end

    context "when all stock is on hand" do

      it "unstocks the items" do
        expect(adjuster).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.first(2)).once
        expect(adjuster).to receive(:unstock_stock_item).with(stock_items[1], inventory_units.last(1)).once
        adjuster.unstock_on_hand(variant, inventory_units)
      end
    end

    context "when there is no stock on hand" do

      let(:count_on_hand) { 0 }

      context "available feeder" do

        let(:feeder_stock_items) {  2.times.map { mock_model(Spree::StockItem, count_on_hand: 2, backorderable?: false) }  }

        before do
          allow(adjuster).to receive(:feeder_stock_items).with(variant).and_return(feeder_stock_items)
        end

        it "does not try to unstock stock item" do
          expect(adjuster).to_not receive(:unstock_stock_item)
          adjuster.unstock_on_hand(variant, inventory_units)
        end

        it "set the state to awaiting_feed" do
          inventory_units.each do |iu|
            expect(iu).to receive(:state=).with(:awaiting_feed).ordered
            expect(iu).to receive(:save).ordered
          end
          adjuster.unstock_on_hand(variant, inventory_units)
        end

      end

      context "no feeders but backordering allowed" do

        let(:backorderable) { true }

        it "does not try to unstock stock item" do
          expect(adjuster).to_not receive(:unstock_stock_item)
          adjuster.unstock_on_hand(variant, inventory_units)
        end

        it "set the state to backordered" do
          inventory_units.each do |iu|
            expect(iu).to receive(:state=).with(:backordered).ordered
            expect(iu).to receive(:save).ordered
          end
          adjuster.unstock_on_hand(variant, inventory_units)
        end

      end

      context "no feeder and backordering not allowed" do

        it "does try to unstock stock item" do
          expect(adjuster).to receive(:unstock_stock_item).with(stock_items.first, inventory_units)
          adjuster.unstock_on_hand(variant, inventory_units)
        end

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

    it "Calls save on each of the inventory units" do
      stock_movements = double('StockMovement')
      expect(stock_movements).to receive(:create!).once.with(quantity: -2, originator: shipment)
      expect(stock_item).to receive(:stock_movements).once.and_return(stock_movements)

      units.each do |iu|
        expect(iu).to receive(:supplier=).with(supplier)
        expect(iu).to receive(:save)
      end

      subject.send(:unstock_stock_item, stock_item, units)
    end

    it "sets inventory unit attributes" do
      # Creates a stock movement
      stock_movements = double('StockMovement')
      expect(stock_movements).to receive(:create!).once.with(quantity: -2, originator: shipment)
      expect(stock_item).to receive(:stock_movements).once.and_return(stock_movements)


      subject.send(:unstock_stock_item, stock_item, units)

      # Updates the supplier
      expect(order.inventory_units.pluck(:supplier_id)).to eq [22, 22] # the ID of the supplier

      # Shoud not update the pending state 
      expect(order.inventory_units.pluck(:pending)).to eq [true, true]

      # Updates the stock_item last_unstocked_at time
      expect(stock_item.last_unstocked_at).to be_within(1.second).of(Time.now)
    end

    context "when the stock item has no supplier" do
      let(:supplier) { nil }

      before do
        stock_movements = double('StockMovement')
        allow(stock_item).to receive(:stock_movements).and_return(stock_movements)
        allow(stock_movements).to receive(:create!)
      end

      it "sends an airbrake notification" do
        # notifier = double
        #expect(notifier).to receive(:notify).with("Stock Item has no supplier", notification_params)
        #expect(Helpers::AirbrakeNotifier).to receive(:delay).and_return(notifier)
        # async above sync below
        expect(Helpers::AirbrakeNotifier).to receive(:notify).with("Stock Item has no supplier", kind_of(Hash)).and_call_original
        adjuster.send(:unstock_stock_item, stock_item, units)
      end
    end
  end


  describe "#clear_total_on_hand_cache" do
    it "should call #clear_total_on_hand_cache on Stock Quantifier" do
      expect(Spree::Stock::Quantifier).to receive(:new).with(variant).and_call_original
      expect_any_instance_of(Spree::Stock::Quantifier).to receive(:clear_total_on_hand_cache)

      subject.send(:clear_total_on_hand_cache, variant)
    end
  end

end
