require 'spec_helper'

describe Spree::Promotion::Actions::FreeShipping, :type => :model do
  let(:order) { create(:completed_order) }
  let(:promotion) { create(:promotion) }
  let(:action) { Spree::Promotion::Actions::FreeShipping.create }
  let(:payload) { { order: order } }
  let(:first_shipment) { order.shipments.first }
  let(:second_shipment) { create(:shipment) }

  # From promotion spec:
  context "#perform" do
    before do
      order.shipments << second_shipment
      promotion.promotion_actions << action
      allow(action).to receive(:shipping_methods).and_return([
        first_shipment.shipping_rates.first.shipping_method,
        second_shipment.shipping_rates.first.shipping_method,
      ])
    end

    it "should create a discount with correct negative amount" do
      expect(order.shipments.count).to eq(2)
      expect(order.shipments.first.selected_shipping_rate.cost).to eq(100)
      expect(order.shipments.last.selected_shipping_rate.cost).to eq(100)
      expect(action.perform(payload)).to be true
      expect(promotion.credits_count).to eq(2)
      expect(order.shipping_rate_adjustments.count).to eq(2)
      expect(order.shipping_rate_adjustments.first.amount.to_i).to eq(-100)
      expect(order.shipping_rate_adjustments.last.amount.to_i).to eq(-100)
    end

    it "should not create a discount when order already has one from this promotion" do
      expect(action.perform(payload)).to be true
      expect(action.perform(payload)).to be false
      expect(promotion.credits_count).to eq(2)
      expect(order.shipping_rate_adjustments.count).to eq(2)
    end

    context "selected shipping_methods" do
      before do
        allow(action).to receive(:shipping_methods).and_return([
          first_shipment.shipping_rates.first.shipping_method
        ])
      end

      it "should not create a discount when order already has one from this promotion" do
        expect(action.perform(payload)).to be true
        expect(action.perform(payload)).to be false
        expect(promotion.credits_count).to eq(1)
        expect(order.shipping_rate_adjustments.count).to eq(1)
      end

    end

  end
end
