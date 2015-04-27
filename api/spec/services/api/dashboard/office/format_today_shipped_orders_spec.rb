require "spec_helper"

module Api
  module Dashboard
    module Office
      describe FormatTodaySells, type: :interaction do
        let(:usd_order) do
          build_stubbed(:order, completed_at: Time.zone.now, total: 10, currency: "USD")
        end

        let(:eur_order) do
          build_stubbed(:order, completed_at: Time.zone.now, total: 11, currency: "EUR")
        end

        let(:gbp_order) do
          build_stubbed(:order, completed_at: Time.zone.now, total: 12, currency: "GBP")
        end

        subject { described_class.new(Spree::Order.complete) }

        describe "execute" do
          it "returns todays orders by currency" do
            allow_any_instance_of(FindTodayValidOrders).to receive(:run).and_return([usd_order,
                                                                                     eur_order,
                                                                                     gbp_order])

            expect(subject.run).to eq("EUR" => BigDecimal.new(11),
                                      "GBP" => BigDecimal.new(12),
                                      "USD" => BigDecimal.new(10))
          end
        end
      end
    end
  end
end
