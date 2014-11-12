require 'spec_helper'

module Spree
  module Calculator::Shipping
    describe PerItem do
      let(:variant1) { build(:variant) }
      let(:variant2) { build(:variant) }

      let(:line_item1) { build(:line_item, quantity: 5, variant: variant1, price: 10) }
      let(:line_item2) { build(:line_item, quantity: 3, variant: variant2, price: 10) }

      let(:package) do
        build(:stock_package, line_items: [ line_item1, line_item2])
      end

      subject { PerItem.new(:preferred_amount => 10) }

      it "correctly calculates per item shipping" do
        subject.compute(package).to_f.should == 80 # 5 x 10 + 3 x 10
      end
    end
  end
end
