require 'spec_helper'

describe Spree::Calculator::FlatPercentItemTotal do
  let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new }
  let(:line_item) { mock_model Spree::LineItem }

  before { allow(calculator).to receive_messages :preferred_flat_percent => 10 }

  context "compute" do
    it "should round result correctly" do
      allow(line_item).to receive_messages :amount => 31.08
      expect(calculator.compute(line_item)).to eq(3.11)

      allow(line_item).to receive_messages :amount => 31.00
      expect(calculator.compute(line_item)).to eq(3.10)
    end
  end
end
