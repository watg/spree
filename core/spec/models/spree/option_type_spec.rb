require 'spec_helper'

describe Spree::OptionType do

  let(:option_type) { build(:option_type, name: 'color', sku_part: nil, presentation: nil) }

  context "update_name_and_sku_part" do

    it "should update name and sku_part based on the presentation" do
      expect(option_type.presentation).to be_nil
      expect(option_type.sku_part).to be_nil
      option_type.save
      expect(option_type.presentation).to eq 'Color'
      expect(option_type.sku_part).to eq 'COL'
    end

  end

  context "option_values" do

    let(:option_value) { build(:option_value, name: 'hot-pink', sku_part: nil, presentation: nil, option_type: nil) }
    let(:option_value_2) { build(:option_value, name: 'hot-pink', sku_part: nil, presentation: nil, option_type: nil) }

    before do
      option_type.option_values << option_value
      option_type.option_values << option_value_2
    end

    it "should deal with duplicates" do
      option_type.save
      option_value.save
      option_value_2.save
      expect(option_value.sku_part).to eq 'HO_PI'
      expect(option_value_2.sku_part).to eq 'HO_PI_1'
    end

  end

  context "touching" do

    before { Delayed::Worker.delay_jobs = false }
    after { Delayed::Worker.delay_jobs = true }

    it "should touch a product" do
      product_option_type = create(:product_option_type)
      option_type = product_option_type.option_type
      product = product_option_type.product
      product.update_column(:updated_at, 1.day.ago)
      option_type.touch
      product.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end
  end
end
