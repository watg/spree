require 'spec_helper'

describe Spree::ShipmentStockAdjuster do

  let(:stock_location) { mock_model(Spree::StockLocation) }
  let(:shipment) { mock_model(Spree::Shipment, stock_location: stock_location) }
  let(:supplier) { mock_model(Spree::Supplier, id: 22) }
  let(:variant) { mock_model(Spree::Variant) }
  let(:order) { Spree::Order.new }

  let(:inventory_units) { 3.times.map { mock_model(Spree::InventoryUnit, line_item: nil, supplier: supplier, variant: variant, state: 'on_hand') } }
  subject { described_class.new(shipment)  }

  context "restock" do

    it "restocks all the inventory_units" do
      expect(stock_location).to receive(:restock).with(variant, 3, shipment, supplier)
      inventory_units.stub(:update_all)
      subject.restock(variant, inventory_units)
    end

    it "sets inventory_units` supplier to nil and their pending state to true" do
      units = []
      units << Spree::InventoryUnit.create(order: order, pending: false, supplier_id: 1)
      units << Spree::InventoryUnit.create(order: order, pending: false, supplier_id: 2)
      stock_location.stub(:restock)

      subject.restock(variant, units)
      expect(order.inventory_units.pluck(:supplier_id)).to eq [nil, nil]
      expect(order.inventory_units.pluck(:pending)).to eq [true, true]
    end

  end


  context "unstock" do
    let(:stock_items) {  2.times.map { mock_model(Spree::StockItem, count_on_hand: 2, backorderable?: true) }  }

    it "calls available_stock_items" do
      subject.stub(:unstock_stock_item)
      expect(subject).to receive(:available_items).with(variant).once.and_return([])
      subject.unstock(variant, inventory_units)
    end

    before do
      subject.stub(:available_items).and_return(stock_items)
    end

    context "on_hand and in stock" do

      it "assigns stock" do
        expect(subject).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.slice(0,2)).once
        expect(subject).to receive(:unstock_stock_item).with(stock_items[1], inventory_units.slice(2,1)).once
        subject.unstock(variant, inventory_units)
      end
    end

    context "on_hand and some in stock" do

      before do
        stock_items[1].stub(:count_on_hand).and_return 0
      end

      it "assigns stock" do
        expect(subject).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.slice(0,2)).once
        # The second call will be to deal with the on_hand which is not in stock
        expect(subject).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.slice(2,1)).once
        subject.unstock(variant, inventory_units)
      end

    end

    context "on_hand and none in stock" do

      before do
        stock_items[0].stub(:count_on_hand).and_return 0
        stock_items[1].stub(:count_on_hand).and_return 0
      end

      it "assigns stock" do
        expect(subject).to_not receive(:unstock_stock_item)
        subject.unstock(variant, inventory_units)
      end

    end


    context "backordered" do

      before do
        inventory_units.map { |iu| iu.stub(:state).and_return('backordered') }
      end

      it "assigns stock which is backordered" do
        expect(subject).to receive(:unstock_stock_item).with(stock_items[0], inventory_units.slice(0,3)).once
        subject.unstock(variant, inventory_units)
      end

      it "does not assigns stock which is backordered if backorderable is false" do
        stock_items.map { |si| si.stub(:backorderable?).and_return(false) }
        expect(subject).to_not receive(:unstock_stock_item)
        subject.unstock(variant, inventory_units)
      end

    end

  end

  context "available_items" do

    it "returns ordered stock_items" do
      ordered_stock_items = double(:ordered_stock_items)
      stock_items = double(:stock_items)
      expect(stock_items).to receive(:order).with(:last_unstocked_at).and_return(ordered_stock_items)
      expect(stock_location).to receive(:available_stock_items).with(variant).and_return(stock_items)
      expect(subject.send(:available_items, variant)).to eq ordered_stock_items
    end

  end

  context "unstock_stock_item" do
    let(:stock_item) { Spree::StockItem.create!(backorderable: true, supplier: supplier, variant: variant, stock_location: stock_location) }
    let(:units) { [] }

    before do
      allow(variant).to receive(:touch)
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
