require 'spec_helper'

describe Spree::OrderPopulator do
  let(:selected_variant) { create(:variant) }
  let(:order) { create(:order) }
  subject { Spree::OrderPopulator.new(order,'GBP') }

  describe "Class Method" do
    let(:assembly_definition_parts) { [double(id: 23, count: 3, optional: false)] }
    let(:assembly_definition) { double(parts: assembly_definition_parts) }
    let(:kit) { create(:variant) }
    subject { Spree::OrderPopulator }
    before do
      allow_any_instance_of(Spree::Variant).to receive(:assembly_definition).and_return(assembly_definition)
    end
    it "returns a list of selected variants with defined quantity" do
      actual = subject.parse_options(kit, {23 =>  selected_variant.id}, 'USD' )
      expect(actual).to match_array([ 
        OpenStruct.new(
          assembly_definition_part_id: 23, 
          variant_id: selected_variant.id,
          quantity: 3,
          optional: false,
          price: nil,
          currency: "USD")])

    end
  end

  describe "#check_stock_levels_for_variant_and_options" do

    it "returns true when order can be supplied" do
      allow(Spree::Stock::Quantifier).
        to receive(:can_supply_order?).
        and_return({in_stock: true, errors: []})

      expect(subject.send(:check_stock_levels_for_variant_and_options, selected_variant, 1, [], [])).
        to eq true
    end

    it "returns false when order cannot be supplied" do
      allow(Spree::Stock::Quantifier).
        to receive(:can_supply_order?).
        and_return({in_stock: false, errors: ["Oops this is out of stock"]})

      expect(subject.send(:check_stock_levels_for_variant_and_options, selected_variant, 10, [], [])).
        to eq false
      expect(subject.order.errors[:base]).to match_array(["Oops this is out of stock"])
    end
  end
end
