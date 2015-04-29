describe Shipments::Destroyer do
  let!(:shipment) { mock_model(Spree::Shipment, shipping_rates: []) }
  let!(:shipping_rate_1) { mock_model(Spree::ShippingRate, selected: true, adjustments: []) }
  let!(:shipping_rate_2) { mock_model(Spree::ShippingRate, selected: false, adjustments: []) }
  let!(:adjustment_1) { mock_model(Spree::Adjustment) }
  let!(:adjustment_2) { mock_model(Spree::Adjustment) }
  let!(:adjustment_3) { mock_model(Spree::Adjustment) }

  before do
    shipping_rate_1.adjustments << adjustment_1
    shipping_rate_1.adjustments << adjustment_2
    shipping_rate_2.adjustments << adjustment_3
    shipment.shipping_rates << shipping_rate_1
    shipment.shipping_rates << shipping_rate_2
  end

  subject { described_class.new(shipment) }

  describe "#destroy" do
    it "returns deletes the shipping rate" do
      expect(adjustment_1).to receive(:delete).once
      expect(adjustment_2).to receive(:delete).once
      expect(adjustment_3).to receive(:delete).once
      expect(shipping_rate_1).to receive(:delete)
      expect(shipping_rate_2).to receive(:delete)
      expect(shipment).to receive(:delete)
      subject.destroy
    end
  end
end
