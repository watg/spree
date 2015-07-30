require "spec_helper"

describe OrderPresenter do
  let(:order)  { build_stubbed(:order) }
  let!(:shipment) { create(:shipment, order: order) }
  subject { described_class.new(order, {}) }

  describe "#has_step?" do
    context "order has desired desired step" do
      it "returns true" do
        order.state = "delivery"
        expect(subject.has_step?("delivery")).to eq true
      end
    end

    context "order does not have desired step" do
      before do
        order.state = "cart"
        allow(order).to receive(:checkout_steps).and_return([])
      end

      it "returns false" do
        expect(subject.has_step?("delivery")).to eq false
      end
    end
  end

  describe "#display_shipments" do
    it "displays shipment information for order" do
      expect(subject.display_shipments).to include("Shacklewell : UPS Ground")
    end
  end

  describe "#display_delivery_time" do
    let(:shipping_method) { mock_model(Spree::ShippingMethod) }
    let(:duration) { mock_model(Spree::ShippingMethodDuration) }

    it "displays estimated delivery time" do
      allow_any_instance_of(Spree::Shipment).to receive(:shipping_method).and_return(shipping_method)
      allow(shipping_method).to receive(:shipping_method_duration).and_return(duration)
      allow(duration).to receive(:dynamic_description).and_return("up to 2 days")

      expect(subject.display_delivery_time).to include("up to 2 days")
    end
  end

  describe "#adjustments_excluding_shipping_and_tax" do
    let(:order)  { build_stubbed(:order) }
    let(:adjustable_type) { "Spree::LineItem" }
    let(:adjustment) do
      build_stubbed(:adjustment,
                    eligible: true,
                    adjustable_type: adjustable_type,
                    source_type: "Spree::PromotionAction")
    end

    let(:adjustable_type_2) { "Spree::ShippingRate" }
    let(:adjustment_2) do
      build_stubbed(:adjustment,
                    eligible: true,
                    adjustable_type: adjustable_type_2,
                    source_type: "Spree::PromotionAction")
    end

    let(:adjustable_type_3) { "Spree::LineItem" }
    let(:adjustment_3) do
      build_stubbed(:adjustment,
                    eligible: true,
                    adjustable_type: adjustable_type_3,
                    source_type: "Spree::TaxRate")
    end

    before do
      allow(order).to receive(:all_adjustments).and_return([adjustment])
    end

    it "returns all adjustments except shipping_rates and tax rates" do
      expect(subject.adjustments_excluding_shipping_and_tax).to eq [adjustment]
      expect(subject.adjustments_excluding_shipping_and_tax).to_not include(adjustment_2)
      expect(subject.adjustments_excluding_shipping_and_tax).to_not include(adjustment_3)
    end
  end
end
