require "spec_helper"

describe Spree::ShippingManifestService::ShippingCosts do
  subject { described_class.run(order: order) }

  let(:order) { create(:order, total: 110, ship_total: 10, currency: "USD") }

  describe ".shipping_cost" do
    it "calls described_class with the correct parameters" do
      shipping_coster = double("ShippingCoster")
      expect(Shipping::Coster).to receive(:new).with(order.shipments).and_return(shipping_coster)
      expect(shipping_coster).to receive(:total).once.and_return(10)
      expect(subject.result).to eq BigDecimal.new 10
      # cost = Shipping::Coster.new(order.shipments).total
    end
  end
end
