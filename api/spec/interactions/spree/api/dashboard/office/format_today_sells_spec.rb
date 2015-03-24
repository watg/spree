require "spec_helper"

describe Spree::Api::Dashboard::Office::FormatTodaySells, type: :interaction do
  let(:usd_order) { build_stubbed(:order, completed_at: Time.zone.now, total: 10, currency: "USD") }
  let(:eur_order) { build_stubbed(:order, completed_at: Time.zone.now, total: 11, currency: "EUR") }
  let(:gbp_order) { build_stubbed(:order, completed_at: Time.zone.now, total: 12, currency: "GBP") }
  subject { described_class.new(Spree::Order.complete) }
  describe "execute" do
    it "returns todays orders by currency" do
      allow_any_instance_of(Spree::Api::Dashboard::Office::FindTodayValidOrders)
        .to receive(:run).and_return([usd_order, eur_order, gbp_order])
      expect(subject.run).to eq(
                               "EUR" => BigDecimal.new(11),
                               "GBP" => BigDecimal.new(12),
                               "USD" => BigDecimal.new(10)
                             )
    end
  end
end
