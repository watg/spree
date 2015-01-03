require 'spec_helper'

describe Spree::Calculator::FlatRate do
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
      allow(order).to receive_messages :currency => "GBP"
      expect(calculator.compute(order)).to eq 10

      allow(order).to receive_messages :currency => "EUR"
      expect(calculator.compute(order)).to eq 20

      allow(order).to receive_messages :currency => "USD"
      expect(calculator.compute(order)).to eq 30
    end
  end
end
