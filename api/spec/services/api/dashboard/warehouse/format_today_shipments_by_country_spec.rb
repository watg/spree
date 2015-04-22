require "spec_helper"

describe Api::Dashboard::Warehouse::FormatTodayShipmentsByCountry, type: :interaction do
  let!(:address) { create(:address) }

  let!(:shipment1) do
    create(:shipment, state: "shipped", shipped_at: Time.zone.now, address: address)
  end

  let!(:shipment2) do
    create(:shipment, state: "shipped", shipped_at: Time.zone.now, address: address)
  end

  subject { described_class.new }

  it "it should return the quantity of shipped orders by location" do
    expect(subject.run).to eq([[address.country.name, 2]])
  end
end
