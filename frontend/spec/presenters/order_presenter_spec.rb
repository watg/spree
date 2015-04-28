require 'spec_helper'

describe OrderPresenter do

  let(:order)  { build_stubbed(:order) }
  let!(:shipment) { create(:shipment, order: order) }
  subject { described_class.new(order, {}) }

  describe "#has_step?" do
    context "order has desired desired step" do
      it "returns true" do
        order.state = 'delivery'
        expect(subject.has_step?("delivery")).to eq true
      end
    end

    context "order does not have desired step" do
      before do
        order.state = 'cart'
        allow(order).to receive(:checkout_steps).and_return([])
      end

      it "returns false" do
        expect(subject.has_step?("delivery")).to eq false
      end
    end
  end

  describe "#display_shipments" do
    it 'displays shipment information for order' do
       expect(subject.display_shipments).to include('Shacklewell : UPS Ground')
    end

  end

  describe "#display_delivery_time" do
    let(:shipping_method) { mock_model(Spree::ShippingMethod) }
    let(:duration) {mock_model(Spree::ShippingMethodDuration) }

    it "displays estimated delivery time" do
      Spree::Shipment.any_instance.stub(:shipping_method).and_return(shipping_method)
      allow(shipping_method).to receive(:shipping_method_duration).and_return(duration)
      allow(duration).to receive(:description).and_return("2 Days")

      expect(subject.display_delivery_time).to include("2 Days")
    end
  end
end
