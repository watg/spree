require "spec_helper"

RSpec.describe Spree::ShippingRatePresenter do
  let(:rate) { Spree::ShippingRate.new }
  subject(:presenter) { described_class.new(rate, nil) }

  it "returns the name" do
    allow(rate).to receive(:name).and_return("Test Rate")
    expect(presenter.name).to eq("Test Rate")
  end

  it "returns the cost" do
    allow(rate).to receive(:cost).and_return(15)
    expect(presenter.cost).to eq(15)
  end

  it "returns the adjustment_total" do
    allow(rate).to receive(:adjustment_total).and_return(-15)
    expect(presenter.adjustment_total).to eq(-15)
  end

  describe "#free?" do
    it "returns a value of true if cost + adjustment_total is 0" do
      allow(rate).to receive(:cost).and_return(15)
      allow(rate).to receive(:adjustment_total).and_return(-15)
      expect(presenter.free?).to eq(true)
    end

    it "returns a value of false if cost + adjustment_total is not 0" do
      allow(rate).to receive(:cost).and_return(16)
      allow(rate).to receive(:adjustment_total).and_return(-15)
      expect(presenter.free?).to eq(false)
    end
  end

  describe "#display_cost" do
    it "returns a value of FREE" do
      allow(rate).to receive(:display_cost).and_return("$15")
      allow(presenter).to receive(:free?).and_return(false)
      expect(presenter.display_cost).to eq("$15")
    end

    context "rate is adjusted to a cost of 0" do
      it "returns a value of FREE" do
        allow(presenter).to receive(:free?).and_return(true)
        #allow(rate).to receive(:display_cost).and_return("$15")
        expect(presenter.display_cost).to eq("FREE")
      end
    end
  end

  describe "duration" do
    context "with a shipping_method_duration" do
      it "returns the duration description" do
        allow(rate)
          .to receive_message_chain("shipping_method.dynamic_description")
          .and_return("2-3 days")
        expect(presenter.duration).to eq("2-3 days")
      end
    end

    context "with no shipping_method_duration" do
      it "returns an empty string" do
        allow(rate)
          .to receive_message_chain("shipping_method.dynamic_description")
          .and_return(nil)
        expect(presenter.duration).to eq("")
      end
    end
  end
end
