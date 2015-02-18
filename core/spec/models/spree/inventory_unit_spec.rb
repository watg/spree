require 'spec_helper'

describe Spree::InventoryUnit, :type => :model do
  let(:stock_location) { create(:stock_location_with_items) }
  let(:stock_item) { stock_location.stock_items.order(:id).first }
  let(:shipment) { build(:shipment) }
  let(:order) { build(:order) }


  context "#backordered_for_stock_item" do
    let(:order) do
      order = create(:order)
      order.state = 'complete'
      order.completed_at = Time.now
      order.tap(&:save!)
    end

    let(:shipment) do
      shipment = Spree::Shipment.new
      shipment.stock_location = stock_location
      shipment.shipping_methods << create(:shipping_method)
      shipment.order = order
      # We don't care about this in this test
      allow(shipment).to receive(:ensure_correct_adjustment)
      shipment.tap(&:save!)
    end

    let!(:unit) do
      unit = shipment.inventory_units.build
      unit.state = 'backordered'
      unit.variant_id = stock_item.variant.id
      unit.order_id = order.id
      unit.tap(&:save!)
    end

    # Regression for #3066
    it "returns modifiable objects" do
      units = Spree::InventoryUnit.backordered_for_stock_item(stock_item)
      expect { units.first.save! }.to_not raise_error
    end

    it "finds inventory units from its stock location when the unit's variant matches the stock item's variant" do
      expect(Spree::InventoryUnit.backordered_for_stock_item(stock_item)).to match_array([unit])
    end

    it "does not find inventory units that aren't backordered" do
      on_hand_unit = shipment.inventory_units.build
      on_hand_unit.state = 'on_hand'
      on_hand_unit.variant_id = 1
      on_hand_unit.save!

      expect(Spree::InventoryUnit.backordered_for_stock_item(stock_item)).not_to include(on_hand_unit)
    end

    it "does not find inventory units that don't match the stock item's variant" do
      other_variant_unit = shipment.inventory_units.build
      other_variant_unit.state = 'backordered'
      other_variant_unit.variant = create(:variant)
      other_variant_unit.save!

      expect(Spree::InventoryUnit.backordered_for_stock_item(stock_item)).not_to include(other_variant_unit)
    end

    describe "#waiting_inventory_units_for" do
      let(:earlier_order) do
        order = create(:order)
        order.update_attributes(state: 'complete', completed_at: 2.weeks.ago)
        order
      end
      let(:variant) { stock_item.variant }
      let!(:unit_awaiting_feed) { create(:inventory_unit, shipment: shipment, state: 'awaiting_feed', variant: variant, order: earlier_order) }
      let!(:unit_on_hand) { create(:inventory_unit, shipment: shipment, state: 'on_hand', variant: variant, order: order) }
      let!(:other_on_hand) { create(:inventory_unit, shipment: shipment, state: 'backordered', order: order) }

      it "returns inventory units backordered and awaiting feed" do
        expect(Spree::InventoryUnit.waiting_for_stock_item(stock_item).to_a).
          to match_array([unit_awaiting_feed, unit])
      end
    end

  end

  describe "#waiting_fill" do

    let(:variant) { build(:base_variant) }

    let!(:on_hand) { create(:inventory_unit, shipment: shipment, state: 'on_hand', variant: variant, order: order) }
    let!(:shipped) { create(:inventory_unit, shipment: shipment, state: 'shipped', variant: variant, order: order) }
    let!(:awaiting_feed) { create(:inventory_unit, shipment: shipment, state: 'awaiting_feed', variant: variant, order: order) }
    let!(:backordered) { create(:inventory_unit, shipment: shipment, state: 'backordered', variant: variant, order: order) }

    it "only returns awaiting_feed and backordered" do
      expect(described_class.waiting_fill).to match_array([awaiting_feed, backordered])
    end
  end


  describe "#fill_waiting_unit" do

    context "when the unit is awaiting feed" do
      let(:unit_awaiting_feed) { build(:inventory_unit, shipment: build(:shipment), state: 'awaiting_feed', variant: build(:base_variant), order: build(:order)) }

      it "transitions to on_hand" do
        unit_awaiting_feed.fill_waiting_unit
        expect(unit_awaiting_feed.state).to eq "on_hand"
      end

    end

    context "when the unit is backordered" do
      let(:unit_awaiting_feed) { build(:inventory_unit, shipment: build(:shipment), state: 'backordered', variant: build(:base_variant), order: build(:order)) }

      it "transitions to on_hand" do
        unit_awaiting_feed.fill_waiting_unit
        expect(unit_awaiting_feed.state).to eq "on_hand"
      end

    end

  end

  describe "stock_quantifier" do

    it "instantiates stock Quantifier with the correct arguments" do
      expect(Spree::Stock::Quantifier).to receive(:new).with(subject.variant)
      subject.send(:stock_quantifier)
    end

  end

  describe "state_change_affects_total_on_hand?" do

    context "state is :awaiting_feed" do
      let!(:inventory_unit) { create(:inventory_unit, state: 'awaiting_feed') }

      it "returns true if state has changed" do
        inventory_unit.state = 'on_hand'
        expect(inventory_unit.send(:state_change_affects_total_on_hand?)).to be true
      end
    end

    context "state is not :awaiting_feed" do
      let!(:inventory_unit) { create(:inventory_unit, state: 'on_hand') }

      it "returns true if its new state is :awaiting_feed " do
        inventory_unit.state = 'awaiting_feed'
        expect(inventory_unit.send(:state_change_affects_total_on_hand?)).to be true
      end

      it "returns false if its new state is not :awaiting_feed " do
        inventory_unit.state = 'backordered'
        expect(inventory_unit.send(:state_change_affects_total_on_hand?)).to be false
      end
    end

  end


  describe "clear_total_on_hand_cache" do

    let(:variant) { build_stubbed(:variant) }

    let!(:inventory_unit) { build_stubbed(:inventory_unit, variant: variant) }
    let(:stock_quantifier) { Spree::Stock::Quantifier.new(variant)}
    let (:return_value) { true }

    before do
      allow(inventory_unit).to receive(:stock_quantifier).and_return(stock_quantifier)
      allow(inventory_unit).to receive(:state_change_affects_total_on_hand?).and_return(return_value)
    end

    it "responds to clear_total_on_hand_cache" do
      expect(stock_quantifier).to respond_to(:clear_total_on_hand_cache)
    end

    context "state is awaiting_feed" do
      it "is called if state_changed? includes awaiting_feed" do
        expect(stock_quantifier).to receive(:clear_total_on_hand_cache)
        inventory_unit.send(:clear_total_on_hand_cache)
      end
    end

    context "state is not awaiting_feed" do
      let (:return_value) { false }
      it "is not called if state_changed? does not include awaiting_feed" do
        expect(stock_quantifier).to_not receive(:clear_total_on_hand_cache)
        inventory_unit.send(:clear_total_on_hand_cache)
      end
    end
  end


  context "other shipments" do
    let(:other_order) do
      order = create(:order)
      order.state = 'payment'
      order.completed_at = nil
      order.tap(&:save!)
    end

    let(:other_shipment) do
      shipment = Spree::Shipment.new
      shipment.stock_location = stock_location
      shipment.shipping_methods << create(:shipping_method)
      shipment.order = other_order
      # We don't care about this in this test
      shipment.stub(:ensure_correct_adjustment)
      shipment.tap(&:save!)
    end

    let!(:other_unit) do
      unit = other_shipment.inventory_units.build
      unit.state = 'backordered'
      unit.variant_id = stock_item.variant.id
      unit.order_id = other_order.id
      unit.tap(&:save!)
    end

    it "does not find inventory units belonging to incomplete orders" do
      Spree::InventoryUnit.backordered_for_stock_item(stock_item).should_not include(other_unit)
    end

  end

  context "variants deleted" do
    let!(:unit) do
      Spree::InventoryUnit.create(variant: stock_item.variant)
    end

    it "can still fetch variant" do
      unit.variant.destroy
      expect(unit.reload.variant).to be_a Spree::Variant
    end

    it "can still fetch variants by eager loading (remove default_scope)" do
      skip "find a way to remove default scope when eager loading associations"
      unit.variant.destroy
      expect(Spree::InventoryUnit.joins(:variant).includes(:variant).first.variant).to be_a Spree::Variant
    end
  end

  #context "#finalize_units!" do
  #  let!(:stock_location) { create(:stock_location) }
  #  let(:variant) { create(:variant) }
  #  let(:inventory_units) { [
  #    create(:inventory_unit, variant: variant),
  #    create(:inventory_unit, variant: variant)
  #  ] }

  #  it "should create a stock movement" do
  #    Spree::InventoryUnit.finalize_units!(inventory_units)
  #    expect(inventory_units.any?(&:pending)).to be false
  #  end
  #end

  describe "#current_or_new_return_item" do
    before { allow(inventory_unit).to receive_messages(pre_tax_amount: 100.0) }

    subject { inventory_unit.current_or_new_return_item }

    context "associated with a return item" do
      let(:return_item) { create(:return_item) }
      let(:inventory_unit) { return_item.inventory_unit }

      it "returns a persisted return item" do
        expect(subject).to be_persisted
      end

      it "returns it's associated return_item" do
        expect(subject).to eq return_item
      end
    end

    context "no associated return item" do
      let(:inventory_unit) { create(:inventory_unit) }

      it "returns a new return item" do
        expect(subject).to_not be_persisted
      end

      it "associates itself to the new return_item" do
        expect(subject.inventory_unit).to eq inventory_unit
      end
    end
  end

  describe '#additional_tax_total' do
    let(:quantity) { 2 }
    let(:line_item_additional_tax_total)  { 10.00 }
    let(:line_item) do
      build(:line_item, {
        quantity: quantity,
        additional_tax_total: line_item_additional_tax_total,
      })
    end

    subject do
      build(:inventory_unit, line_item: line_item)
    end

    it 'is the correct amount' do
      expect(subject.additional_tax_total).to eq line_item_additional_tax_total / quantity
    end
  end

  describe '#included_tax_total' do
    let(:quantity) { 2 }
    let(:line_item_included_tax_total)  { 10.00 }
    let(:line_item) do
      build(:line_item, {
        quantity: quantity,
        included_tax_total: line_item_included_tax_total,
      })
    end

    subject do
      build(:inventory_unit, line_item: line_item)
    end

    it 'is the correct amount' do
      expect(subject.included_tax_total).to eq line_item_included_tax_total / quantity
    end
  end

  describe '#additional_tax_total' do
    let(:quantity) { 2 }
    let(:line_item_additional_tax_total)  { 10.00 }
    let(:line_item) do
      build(:line_item, {
        quantity: quantity,
        additional_tax_total: line_item_additional_tax_total,
      })
    end

    subject do
      build(:inventory_unit, line_item: line_item)
    end

    it 'is the correct amount' do
      expect(subject.additional_tax_total).to eq line_item_additional_tax_total / quantity
    end
  end

  describe '#included_tax_total' do
    let(:quantity) { 2 }
    let(:line_item_included_tax_total)  { 10.00 }
    let(:line_item) do
      build(:line_item, {
        quantity: quantity,
        included_tax_total: line_item_included_tax_total,
      })
    end

    subject do
      build(:inventory_unit, line_item: line_item)
    end

    it 'is the correct amount' do
      expect(subject.included_tax_total).to eq line_item_included_tax_total / quantity
    end
  end
end
