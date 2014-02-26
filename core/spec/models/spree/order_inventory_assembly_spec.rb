require 'spec_helper'

describe Spree::OrderInventoryAssembly do
  let(:line_item)     { create(:line_item) }
  let(:lots_of_variant_units) { Array.new(100) }
  let(:no_variant_unit) { [] }
  let(:shipment)      { double('shipment') }
  subject { Spree::OrderInventoryAssembly.new(line_item) }

  it "removing kit from the backend to an order" do
    subject.stub(:inventory_units_for).and_return(lots_of_variant_units)

    expect(subject).to receive(:remove).with(line_item.variant, line_item.quantity, lots_of_variant_units, nil)
    subject.send(:add_kit_variant, line_item)
  end

  it "adds kit to order from backend" do
    subject.stub(:inventory_units_for).and_return(no_variant_unit)
    subject.stub(:determine_target_shipment).and_return(shipment)

    expect(subject).to receive(:add_to_shipment).with(shipment, line_item.variant, line_item.quantity)
    subject.send(:add_kit_variant, line_item)
  end
end
