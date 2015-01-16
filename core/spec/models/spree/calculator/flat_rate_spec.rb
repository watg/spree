require 'spec_helper'

describe Spree::Calculator::FlatRate, type: :model do
  let(:calculator) { Spree::Calculator::FlatRate.new }
  let(:order) { mock_model Spree::Order }

  before do
    calculator.preferred_amount = [
      {type: :integer, name: "GBP", value: 10},
      {type: :integer, name: "EUR", value: 20},
      {type: :integer, name: "USD", value: 30}
    ]
  end

  context "compute" do
    it "should discount with the correct currency" do
      order.stub :currency => "GBP"
      expect(calculator.compute(order)).to eq 10

      order.stub :currency => "EUR"
      expect(calculator.compute(order)).to eq 20

      order.stub :currency => "USD"
      expect(calculator.compute(order)).to eq 30
    end
  end

# This is the old specs ( vanilla spree, before we made changes to the way the promotion works )
#  let(:order) do
#    mock_model(
#      Spree::Order, quantity: 10, currency: "USD"
#    )
#  end

# This is the old specs ( vanilla spree, before we made changes to the way the promotion works )
#  context "compute" do
#    it "should compute the amount as the rate when currency matches the order's currency" do
#      calculator.preferred_amount = 25.0
#      calculator.preferred_currency = "GBP"
#      allow(order).to receive_messages currency: "GBP"
#      expect(calculator.compute(order).round(2)).to eq(25.0)
#    end
#
#    it "should compute the amount as 0 when currency does not match the order's currency" do
#      calculator.preferred_amount = 100.0
#      calculator.preferred_currency = "GBP"
#      allow(order).to receive_messages currency: "USD"
#      expect(calculator.compute(order).round(2)).to eq(0.0)
#    end
#
#    it "should compute the amount as 0 when currency is blank" do
#      calculator.preferred_amount = 100.0
#      calculator.preferred_currency = ""
#      allow(order).to receive_messages currency: "GBP"
#      expect(calculator.compute(order).round(2)).to eq(0.0)
#    end
#
#    it "should compute the amount as the rate when the currencies use different casing" do
#      calculator.preferred_amount = 100.0
#      calculator.preferred_currency = "gBp"
#      allow(order).to receive_messages currency: "GBP"
#      expect(calculator.compute(order).round(2)).to eq(100.0)
#    end
#
#    it "should compute the amount as 0 when there is no object" do
#      calculator.preferred_amount = 100.0
#      calculator.preferred_currency = "GBP"
#      expect(calculator.compute.round(2)).to eq(0.0)
#    end
#  end
end
