require "spec_helper"

describe Shipping::AdjustmentsUpdater do
  let!(:shipment) { mock_model(Spree::Shipment) }
  let!(:selected_rate) { mock_model(Spree::ShippingRate, selected: true) }
  let!(:shipping_rate) { mock_model(Spree::ShippingRate, selected: false) }
  let!(:adjustment) { mock_model(Spree::Adjustment) }
  let!(:selector) { double(Adjustments::Selector) }

  subject { described_class.new([selected_rate, shipping_rate]) }
  describe "#update" do
    it "updates the adjustments on the shipping rate" do
      expect(adjustment).to receive(:update!).twice
      expect(subject).to receive(:shipping_rate_adjustments)
        .with(selected_rate).once
        .and_return([adjustment])

      expect(subject).to receive(:shipping_rate_adjustments)
        .with(shipping_rate).once
        .and_return([adjustment])

      subject.update
    end
  end

  describe "#shipping_rate_adjustments" do
    before do
      allow(selected_rate).to receive(:adjustments).and_return([adjustment])
    end

    it "calls the shipping rate selector and returns correct adjustments" do
      expect(selector).to receive(:additional).and_return([adjustment])
      expect(Adjustments::Selector).to receive(:new).with([adjustment]).and_return(selector)
      expect(subject.send(:shipping_rate_adjustments, selected_rate)).to eq [adjustment]
    end
  end
end