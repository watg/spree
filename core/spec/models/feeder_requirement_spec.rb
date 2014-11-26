require 'spec_helper'

describe Spree::FeederRequirement do
  subject(:feeder_requirement) { Spree::FeederRequirement.new }

  describe "#list" do
    let(:v1) { create(:variant) }
    let(:v2) { create(:variant) }
    let(:location1) { create(:stock_location) }
    let(:location2) { create(:stock_location) }
    let(:shipment1) { create(:shipment, stock_location: location1) }
    let(:shipment2) { create(:shipment, stock_location: location2) }

    before do
      create_list(:inventory_unit, 2, state: "awaiting_feed", variant: v1, shipment: shipment1)
      create_list(:inventory_unit, 1, state: "awaiting_feed", variant: v2, shipment: shipment1)
      create_list(:inventory_unit, 2, state: "awaiting_feed", variant: v2, shipment: shipment2)

      # Older inventory units should be ignored
      create_list(:inventory_unit, 2,
        state: "awaiting_feed", variant: v1, shipment: shipment1, created_at: 2.days.ago
      )
    end


    it "returns a mapping of {location => { variant => count }} for last 24 hours" do
      expected = {
        location1 => {
          v1 => 2,
          v2 => 1,
        },
        location2 => {
          v2 => 2,
        },
      }

      expect(feeder_requirement.list).to eq(expected)
    end
  end

  describe "#plan" do
    context "when there is a single location" do
      let(:location) { create(:stock_location) }
      let(:feeder) { create(:stock_location, active: false, feed_into: location) }
      let(:feeders) { [feeder] }
      let(:variant) { create(:variant) }
      let(:list) { { location => { variant => 3 } } }

      before do
        allow(feeder_requirement).to receive(:list).and_return(list)
        allow(location).to receive(:feeders).and_return(feeders)
      end

      context "when there is more than enough stock in a single feeder" do
        before do
          allow(feeder).to receive(:count_on_hand).with(variant).and_return(10)
        end

        it "moves all required stock from the feeder" do
          expected = { location => { feeder => { variant => 3 } } }
          expect(feeder_requirement.plan).to eq(expected)
        end
      end

      context "when there is partial stock in a single feeder" do
        before do
          allow(feeder).to receive(:count_on_hand).with(variant).and_return(2)
        end

        it "moves the available stock from the feeder" do
          expected = { location => { feeder => { variant => 2 } } }
          expect(feeder_requirement.plan).to eq(expected)
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
          expect(feeder_requirement.plan).to eq(expected)
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
        allow(feeder_requirement).to receive(:list).and_return(list)
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
        expect(feeder_requirement.plan).to eq(expected)
      end
    end
  end
end
