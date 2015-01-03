## encoding: utf-8

require 'spec_helper'

describe Spree::Personalisation do
  let(:personalisation) { build(:personalisation_monogram) }

  context "#name" do
    subject { personalisation.name }

    it "returns name of the personalisation" do
      expect(subject).to eq('monogram')
    end
  end

  context "#price_in" do
    it "returns price in GBP" do
      expect(personalisation.price_in('GBP')).to eq(BigDecimal.new('7.5')) 
    end
    
    it "returns price in EUR" do
      expect(personalisation.price_in('EUR')).to eq(BigDecimal.new('10.0')) 
    end

    it "returns price in USD" do
      expect(personalisation.price_in('USD')).to eq(BigDecimal.new('10.0')) 
    end
  end

  context "#subunit_price_in" do
    it "returns price in GBP" do
      expect(personalisation.subunit_price_in('GBP')).to eq(750)
    end
    
    it "returns price in EUR" do
      expect(personalisation.subunit_price_in('EUR')).to eq(1000)
    end

    it "returns price in USD" do
      expect(personalisation.subunit_price_in('USD')).to eq(1000) 
    end
  end

  context "touching" do
    it "should touch a product" do
      personalisation = create(:personalisation_monogram)
      product = personalisation.product
      product.update_column(:updated_at, 1.day.ago)
      personalisation.touch
      expect(product.reload.updated_at).to be_within(3.seconds).of(Time.now)
    end
  end


end



