require 'spec_helper'

describe Spree::Price do
  context "touching" do
    it "should touch a variant" do
      price = create(:price)
      variant = price.variant
      variant.update_column(:updated_at, 1.day.ago)
      price.touch
      variant.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end
  end
end
