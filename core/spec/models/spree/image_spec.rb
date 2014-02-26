require 'spec_helper'

describe Spree::Image do

  context "touching" do
    it "should touch a variant" do
      image = create(:image)
      variant = image.viewable
      variant.update_column(:updated_at, 1.day.ago)
      image.touch
      variant.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end
  end

  describe "#variant_id" do
    let!(:variant) { create(:base_variant) }
    let!(:variant_image) { create(:image, viewable: variant) }

    let!(:variant_target) { create(:variant_target, variant: variant) }
    let!(:variant_target_image) { create(:image, viewable: variant_target) }

    it "returns variant id either from the the variant targets table or directly" do
      expect(variant_target_image.variant_id).to eq(variant.id)
      expect(variant_image.variant_id).to eq(variant.id)
    end

  end


end
