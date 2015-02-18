require 'spec_helper'

module Spree
  module Calculator::Shipping
    describe FlatPercentItemTotal do
      let(:variant1) { build(:variant) }
      let(:variant2) { build(:variant) }

      let(:line_item1) { build(:line_item, quantity: 2, variant: variant1, price: 10.11) }
      let(:line_item2) { build(:line_item, quantity: 1, variant: variant2, price: 20.2222) }

      let(:package) do
        build(:stock_package, line_items: [ line_item1, line_item2])
      end

      subject { FlatPercentItemTotal.new(:preferred_flat_percent => 10) }

      it "should round result correctly" do
        expect(subject.compute(package)).to eq(4.04)
      end
    end
  end
end
