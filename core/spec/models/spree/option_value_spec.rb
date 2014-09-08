require 'spec_helper'

describe Spree::OptionValue do

  context "update_presentation_and_sku_part" do

    let(:option_type) { create(:option_type, name: 'color', sku_part: 'COL', presentation: 'Color') }
    let(:option_value) { build(:option_value, name: 'hot-pink', sku_part: nil, presentation: nil, option_type: option_type) }

    it "should update name and sku_part based on the presentation" do
      expect(option_value.presentation).to be_nil
      expect(option_value.sku_part).to be_nil
      option_value.save
      expect(option_value.presentation).to eq 'Hot Pink'
      expect(option_value.sku_part).to eq 'HO_PI'
    end

    context "safe_sku" do
      let(:option_value_2) { build(:option_value, name: 'hot-pink', sku_part: nil, presentation: nil, option_type: option_type) }

      before do
        option_value.save
      end

      it "should deal with duplicates" do
        safe_sku = option_value_2.send(:safe_sku)
        expect(safe_sku).to eq 'HO_PI_1'
      end

    end

  end

  context "touching" do
    it "should touch a variant" do
      variant = create(:variant)
      option_value = variant.option_values.first
      variant.update_column(:updated_at, 1.day.ago)
      option_value.touch
      variant.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end
  end
end
