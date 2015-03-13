require 'spec_helper'

describe Spree::Feed::InventoryUnitRequirement do
  subject(:feeder_requirement) { Spree::Feed::InventoryUnitRequirement.new }

  describe "#list" do
    let(:v1) { create(:variant) }
    let(:v2) { create(:variant) }
    let(:location1) { create(:stock_location) }
    let(:location2) { create(:stock_location) }
    let(:shipment1) { create(:shipment, stock_location: location1) }
    let(:shipment2) { create(:shipment, stock_location: location2) }

    before do
      create_list(:inventory_unit, 2, state: "awaiting_feed", variant: v1, shipment: shipment1, pending: false)
      create_list(:inventory_unit, 1, state: "awaiting_feed", variant: v2, shipment: shipment1, pending: false)
      create_list(:inventory_unit, 2, state: "awaiting_feed", variant: v2, shipment: shipment2, pending: false)

      # Older inventory units should NOT be ignored
      create_list(:inventory_unit, 2,
        state: "awaiting_feed", variant: v1, shipment: shipment1,
        pending: false, created_at: 2.days.ago
      )
    end


    it "returns a mapping of {location => { variant => count }}" do
      expected = {
        location1 => {
          v1 => 4,
          v2 => 1,
        },
        location2 => {
          v2 => 2,
        },
      }

      expect(feeder_requirement.list).to eq(expected)
    end
  end
end
