require 'spec_helper'

describe Spree::Feed::Planner do
  let(:requirement) { double(Spree::Feed::InventoryUnitRequirement, list: list) }
  subject(:planner) { Spree::Feed::Planner.new(Spree::Feed::InventoryUnitRequirement) }

  before do
    allow(Spree::Feed::InventoryUnitRequirement).to receive(:new).and_return(requirement)
  end

  context "when there is a single location" do
    let(:location) { create(:stock_location) }
    let(:feeder) { create(:stock_location, active: false, feed_into: location) }
    let(:feeders) { [feeder] }
    let(:variant) { create(:variant) }
    let(:list) { { location => { variant => 3 } } }

    before do
      allow(location).to receive(:feeders).and_return(feeders)
    end

    context "when there is more than enough stock in a single feeder" do
      before do
        allow(feeder).to receive(:count_on_hand).with(variant).and_return(10)
      end

      it "moves all required stock from the feeder" do
        expected = { location => { feeder => { variant => 3 } } }
        expect(planner.plan).to eq(expected)
      end
    end

    context "when there is partial stock in a single feeder" do
      before do
        allow(feeder).to receive(:count_on_hand).with(variant).and_return(2)
      end

      it "moves the available stock from the feeder" do
        expected = { location => { feeder => { variant => 2 } } }
        expect(planner.plan).to eq(expected)
      end
    end

    context "when there is partial stock in multiple feeders" do
      let(:feeder2) { create(:stock_location, active: false, feed_into: location) }
      let(:feeders) { [feeder, feeder2] }

      before do
        allow(feeder).to receive(:count_on_hand).with(variant).and_return(1)
        allow(feeder2).to receive(:count_on_hand).with(variant).and_return(10)
      end

      it "moves the available stock from the feeder" do
        expected = { location => { feeder => { variant => 1 }, feeder2 => { variant => 2 } } }
        expect(planner.plan).to eq(expected)
      end
    end
  end

  context "when there is stock in multiple feeders for multiple locations"do
    let(:location1) { create(:stock_location) }
    let(:location2) { create(:stock_location) }
    let(:feeder1) { create(:stock_location, active: false, feed_into: location1) }
    let(:feeder2) { create(:stock_location, active: false, feed_into: location2) }
    let(:variant) { create(:variant) }
    let(:list) { { location1 => { variant => 3 }, location2 => { variant => 2 } } }

    before do
      allow(location1).to receive(:feeders).and_return([feeder1])
      allow(location2).to receive(:feeders).and_return([feeder2])

      allow(feeder1).to receive(:count_on_hand).with(variant).and_return(10)
      allow(feeder2).to receive(:count_on_hand).with(variant).and_return(10)
    end

    it "moves all required stock from the feeder" do
      expected = {
        location1 => { feeder1 => { variant => 3 } },
        location2 => { feeder2 => { variant => 2 } },
      }
      expect(planner.plan).to eq(expected)
    end
  end

  context "with multiple lists" do
    let(:st_requirement) { double(Spree::Feed::InventoryUnitRequirement, list: st_list) }

    let(:location) { create(:stock_location) }
    let(:feeder) { create(:stock_location, active: false, feed_into: location) }
    let(:feeders) { [feeder] }
    let(:variant) { create(:variant) }
    let(:list) { { location => { variant => 3 } } }
    let(:st_list) { { location => { variant => 3 } } }

    subject(:planner) {
      Spree::Feed::Planner.new(
        Spree::Feed::InventoryUnitRequirement,
        Spree::Feed::StockThresholdRequirement
      )
    }

    before do
      allow(Spree::Feed::StockThresholdRequirement).to receive(:new).and_return(st_requirement)

      allow(location).to receive(:feeders).and_return(feeders)
      allow(feeder).to receive(:count_on_hand).with(variant).and_return(10)
    end

    it "moves all required stock from the feeder" do
      expected = { location => { feeder => { variant => 6 } } }
      expect(planner.plan).to eq(expected)
    end
  end
end
