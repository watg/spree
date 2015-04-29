describe ShippingRates::Destroyer do
  let!(:shipping_rate) { mock_model(Spree::ShippingRate, selected: true, adjustments: []) }
  let!(:adjustment_1) { mock_model(Spree::Adjustment) }
  let!(:adjustment_2) { mock_model(Spree::Adjustment) }

  before do
    shipping_rate.adjustments << adjustment_1
    shipping_rate.adjustments << adjustment_2
  end

  subject { described_class.new(shipping_rate) }

  describe "#destroy" do
    it "returns deletes the shipping rate" do
      expect(adjustment_1).to receive(:delete).once
      expect(adjustment_2).to receive(:delete).once
      expect(shipping_rate).to receive(:delete)
      subject.destroy
    end
  end
end
