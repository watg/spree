require 'spec_helper'

describe Spree::Image, :type => :model do

  context "touching" do
    it "should touch a variant" do
      image = create(:image)
      variant = image.viewable
      variant.update_column(:updated_at, 1.day.ago)
      image.touch
      expect(variant.reload.updated_at).to be_within(3.seconds).of(Time.now)
    end
  end


end
