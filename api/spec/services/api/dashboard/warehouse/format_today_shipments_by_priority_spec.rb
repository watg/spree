require "spec_helper"

describe Api::Dashboard::Warehouse::FormatTodayShipmentsByPriority, type: :interaction do
  let!(:regular_shipments) do
    create_list(:shipment, 4, state: "shipped", shipped_at: Time.zone.now)
  end

  let!(:old_shipped_shipments) do
    create_list(:shipment, 4, state: "shipped", shipped_at: Time.zone.yesterday)
  end

  let!(:unshipped_shipments) { create_list(:shipment, 4, state: "pending") }

  subject { described_class.new }
  describe "execute" do
    it "returns 3 shippments" do
      expect(subject.run).to include(normal: 4)
    end
  end

  context "with express shipments" do
    let!(:express_shipments) do
      create_list(:shipment, 6, state: "shipped", shipped_at: Time.zone.now)
    end
    before do
      express_shipments.each{ |e| allow(e).to receive(:express?).and_return(true)}
      regular_shipments.each{ |r| allow(r).to receive(:express?).and_return(false)}
    end
    it "returns 3 express shipments and 7 regular ones" do
      allow(subject).to receive(:today_shipments).
                        and_return(express_shipments.concat(regular_shipments))

      expect(subject.run).to include(express: 6)
      expect(subject.run).to include(normal: 4)
    end
  end
end
