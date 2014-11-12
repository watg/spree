require 'spec_helper'

describe Spree::Price do
  let(:variant) { create(:variant)}

  context "touching" do
    it "should touch a variant" do
      price = variant.price_normal_in('USD')
      variant.update_column(:updated_at, 1.day.ago)
      price.touch
      variant.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end
  end

  context ".default_price" do

    it "should return default price" do
      expected = {
        "id"=>nil,
        "variant_id"=>nil, 
        "amount"=> BigDecimal.new('0.0'), 
        "currency"=>"USD", 
        "is_kit"=>false, 
        "sale"=>false, 
        "deleted_at"=>nil
      }
      expect(Spree::Price.default_price.attributes).to eq expected
    end

  end

  context "validates_uniqueness_of" do

    # Choose the GBP currency as variant has a default price with USD
    let(:price) { build(:price, currency: 'GBP',variant: variant) }
    let(:dup_price) { build(:price, currency: 'GBP', variant: variant) }

    it "should not allow duplicate prices" do
      expect(price.valid?).to be_true
      price.save
      expect(dup_price.valid?).to be_false
    end

  end

end
