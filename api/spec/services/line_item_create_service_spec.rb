require 'spec_helper'

describe Spree::Api::LineItemCreateService do

  context "#run" do
    subject { described_class }

    let(:order)   { Spree::Order.new }
    let(:variant) { create(:base_variant) }
    let(:quantity) { 1 }
    let(:options) { {} }

    let(:params) { { 
      order: order,
      variant: variant,
      quantity: quantity,
      options: options,
    } }

    it "returns line item" do
      expect(subject.run!(params)).to be_kind_of(Spree::LineItem)
    end

    context "adding an item to a complete order with no shipments" do
      let(:order)   { Spree::Order.create }

      before do
        order.completed_at = Time.now
        order.shipments = []
      end

      it "creates a shipment when added to a completed order without shipments" do
        expect(order.shipments).to be_empty
        allow(order).to receive(:completed?).and_return true
        subject.run!(params)
        expect(order.shipments).to_not be_empty
      end

    end

  end

end

