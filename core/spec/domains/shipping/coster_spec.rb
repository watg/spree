require "spec_helper"

describe Shipping::Coster do
  let!(:shipment) { mock_model(Spree::Shipment) }
  let!(:selected_rate) { mock_model(Spree::ShippingRate, selected: true) }
  let!(:shipping_rate) { mock_model(Spree::ShippingRate, selected: false) }

  subject { described_class.new([shipment]) }

  describe "#promo_total" do
    it "returns the promo total on selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:promo_total).and_return(-10)

      expect(subject.promo_total).to eq(-10)
    end
  end

  describe "#included_tax_total" do
    it "returns the addition_tax_total on selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:included_tax_total).and_return 10

      expect(subject.included_tax_total).to eq 10
    end
  end

  describe "#additional_tax_total" do
    it "returns the additional_tax_total on selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:additional_tax_total).and_return 12

      expect(subject.additional_tax_total).to eq 12
    end
  end

  describe "#adjustment_total" do
    it "returns the adjustment_total on selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:adjustment_total).and_return(-13)

      expect(subject.adjustment_total).to eq(-13)
    end
  end

  describe "#cost" do
    it "returns the cost of the shipments selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:cost).and_return 50

      expect(subject.cost).to eq 50
    end
  end

  describe "#discounted_cost" do
    it "returns the cost of the shipments selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:cost).and_return 50
      allow(selected_rate).to receive(:promo_total).and_return(-10)

      expect(subject.discounted_cost).to eq 40
    end
  end

  describe "#total" do
    it "returns the total of the shipments selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:cost).and_return 50
      allow(selected_rate).to receive(:adjustment_total).and_return(-15)

      expect(subject.total).to eq 35
    end
  end

  describe "#tax_total" do
    it "returns the total of the shipments selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:included_tax_total).and_return 5
      allow(selected_rate).to receive(:additional_tax_total).and_return 15

      expect(subject.tax_total).to eq 20
    end
  end

  describe "#final_price" do
    it "returns the final_price of the shipments selected shipping rate" do
      allow(shipment).to receive(:selected_shipping_rate).and_return(selected_rate)
      allow(selected_rate).to receive(:cost).and_return 50
      allow(selected_rate).to receive(:adjustment_total).and_return(-15)

      expect(subject.final_price).to eq 35
    end
  end
end
