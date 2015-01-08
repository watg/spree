require 'spec_helper'

describe Spree::Stock::WaitingUnitsProcessor do

  let(:stock_location) { build_stubbed(:stock_location) }
  let(:order) { build_stubbed(:order) }
  let(:shipment) { build_stubbed(:shipment, stock_location: stock_location, order: order) }
  let(:variant) { build_stubbed(:base_variant) }
  let(:stock_item) { Spree::StockItem.new(stock_location: stock_location, variant: variant) }
  let (:inventory_unit_1) { build_stubbed(:inventory_unit, shipment:shipment)}
  let (:inventory_unit_2) { build_stubbed(:inventory_unit, shipment:shipment)}
  let (:stock_allocator) { double(:stock_allocator)}

  subject { described_class.new(stock_item) }

  describe "#perform" do

    before do
      allow(subject).to receive(:stock_allocator).with(shipment).and_return(stock_allocator)
    end

    it "returns if quantity is less than 1" do
      expect(subject).to_not receive(:process_waiting_inventory_units)
      subject.perform(0)
    end

    it "returns if quantity is less than 0" do
      expect(subject).to_not receive(:process_waiting_inventory_units)
      subject.perform(-1)
    end

    it "processes 1 inventory unit if quantity is 1" do
      expect(subject).to receive(:waiting_inventory_units).with(1).and_return([inventory_unit_1])
      expect(inventory_unit_1).to receive(:fill_waiting_unit)
      expect(stock_allocator).to receive(:unstock_on_hand).with(stock_item.variant, [inventory_unit_1] )
      expect(order).to receive(:update!)
      subject.perform(1)
    end

    it "processes 2 inventory unit if quantity is 2" do
      expect(subject).to receive(:waiting_inventory_units).with(2).and_return([inventory_unit_1, inventory_unit_2])
      expect(inventory_unit_1).to receive(:fill_waiting_unit)
      expect(inventory_unit_2).to receive(:fill_waiting_unit)
      expect(stock_allocator).to receive(:unstock_on_hand).with(stock_item.variant, [inventory_unit_1, inventory_unit_2] )
      expect(order).to receive(:update!)
      subject.perform(2)
    end

    context "multiple shipments" do

      let(:order_2) { build_stubbed(:order) }
      let(:shipment_2) { build_stubbed(:shipment, stock_location: stock_location, order: order_2) }
      let(:inventory_unit_2) { build_stubbed(:inventory_unit, shipment:shipment_2)}
      let(:stock_allocator_2) { double(:stock_allocator)}

      before do
        allow(subject).to receive(:stock_allocator).with(shipment_2).and_return(stock_allocator_2)
      end

      it "processes inventory units from different shipments" do
        expect(subject).to receive(:waiting_inventory_units).with(2).and_return([inventory_unit_1, inventory_unit_2])
        expect(inventory_unit_1).to receive(:fill_waiting_unit)
        expect(inventory_unit_2).to receive(:fill_waiting_unit)
        expect(stock_allocator).to receive(:unstock_on_hand).with(stock_item.variant, [inventory_unit_1] )
        expect(stock_allocator_2).to receive(:unstock_on_hand).with(stock_item.variant, [inventory_unit_2] )
        expect(order).to receive(:update!)
        expect(order_2).to receive(:update!)
        subject.perform(2)
      end

    end

  end

  describe "#waiting_inventory_units" do

    it "returns inventory units" do
      mock_inventory_units = double(:inventory_units)
      expect(mock_inventory_units).to receive(:first).with(2).and_return( [inventory_unit_1,inventory_unit_2])
      expect(Spree::InventoryUnit).to receive(:waiting_for_stock_item).with(stock_item).and_return(mock_inventory_units)
      expect(subject.send(:waiting_inventory_units,2)).to eq ([inventory_unit_1, inventory_unit_2])
    end

  end

  describe "#stock_allocator" do

    it "initializes a shipment stock allocator" do
      mock_stock_allocator = double(:stock_allocator)
      expect(Spree::Stock::Allocator).to receive(:new).with(shipment).and_return(mock_stock_allocator)
      expect(subject.send(:stock_allocator, shipment)).to eq mock_stock_allocator
    end

  end

end
