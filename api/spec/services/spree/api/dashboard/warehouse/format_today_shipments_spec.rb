require "spec_helper"

describe Spree::Api::Dashboard::Warehouse::FormatTodayShipments, type: :interaction do
  let!(:shipped_shipments) do
    create_list(:shipment, 4, state: "shipped", shipped_at: Time.zone.now)
  end

  let!(:old_shipped_shipments) do
    create_list(:shipment, 4, state: "shipped", shipped_at: Time.zone.yesterday)
  end

  let!(:unshipped_shipments) { create_list(:shipment, 4, state: "pending") }

  subject { described_class.new }
  describe "execute" do
    it "returns 3 shippments" do
      expect(subject.run).to eq(total: 4)
    end
  end
end
