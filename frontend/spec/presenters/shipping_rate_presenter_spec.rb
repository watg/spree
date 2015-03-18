require "spec_helper"

RSpec.describe Spree::ShippingRatePresenter do
  let(:rate) { Spree::ShippingRate.new }
  subject(:presenter) { described_class.new(rate, nil) }

  it "returns the name" do
    allow(rate).to receive(:name).and_return("Test Rate")
    expect(presenter.name).to eq("Test Rate")
  end

  it "returns the display_cost" do
    allow(rate).to receive(:display_cost).and_return("$15")
    expect(presenter.display_cost).to eq("$15")
  end

  describe "duration" do
    context "with a shipping_method_duration" do
      it "returns the duration description" do
        allow(rate)
          .to receive_message_chain("shipping_method.duration_description")
          .and_return("2-3 days")
        expect(presenter.duration).to eq("2-3 days")
      end
    end

    context "with no shipping_method_duration" do
      it "returns an empty string" do
        allow(rate)
          .to receive_message_chain("shipping_method.duration_description")
          .and_return(nil)
        expect(presenter.duration).to eq("")
      end
    end
  end
end
