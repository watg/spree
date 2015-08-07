require "spec_helper"

describe Admin::Orders::LineItemPresenter do
  describe "#quantity" do
    subject          { described_class.new(item, shipment) }
    let(:item)       { double(item_opts) }
    let(:bag)        { double(normal?: normal?) }
    let(:normal?)    { true }
    let(:parts)      { [double] }
    let(:item_parts) { [item_part, item_part2] }
    let(:item_part)  { double(container?: false, quantity: 1) }
    let(:item_part2) { double(container?: false, quantity: 1) }
    let(:shipment)   { double }
    let(:item_unit)  { double(shipment: shipment) }
    let(:part_unit)  { double(shipment: shipment) }
    let(:part_unit2)  { double(shipment: shipment) }

    let(:item_opts) do
      { inventory_units: units,
        parts: parts,
        line_item_parts: item_parts,
        product: bag,
        quantity: 2
      }
    end

    context "ready made" do
      let(:units) { [item_unit, part_unit, part_unit2] }
      it { expect(subject.quantity).to eq 1 }
    end

    context "kit" do
      let(:normal?) { false }
      let(:units)   { [part_unit, part_unit2] }
      it { expect(subject.quantity).to eq 1 }
    end
  end
end
