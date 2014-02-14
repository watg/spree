require 'spec_helper'

describe Spree::OptionValue do
  let(:pink)    { create(:option_value, name: 'pink') }
  let(:blue)    { create(:option_value, name: 'blue', 
                         option_type: pink.option_type, 
                         presentation: 'blue') }


  context "class methods" do
    subject { Spree::OptionValue }
    let(:women)   { create(:target, name:'Women') }
    let(:men)     { create(:target, name:'Men') }
    let(:kid)     { create(:target, name:'Kid') }
    let(:product) { create(:product_with_variants) }

    before do
      pink_v = product.variants.first
      pink_v.option_values= [pink]
      pink_v.targets= [women]
      pink_v.save

      blue_v = product.variants.last
      blue_v.option_values= [blue]
      blue_v.targets= [men]
      blue_v.save
    end

    it "returns all option values available to a product" do
      expect(subject.for_product(product, false)).to match_array([pink,blue])
    end

    it "returns option values for targeted variants" do
      expect(subject.for_product(product, false).with_target(women)).to match_array([pink])
      expect(subject.for_product(product, false).with_target(men)).to   match_array([blue])
      expect(subject.for_product(product, false).with_target(kid)).to   be_blank
    end
    
    context "stock" do
      let(:first_variant) { product.variants.first }
      before do
        first_variant.in_stock_cache = true
        first_variant.save
      end
      it "returns option values for varaiant in stock" do
        expect(subject.for_product(product, true)).to match_array([pink])
      end

      it "filters out option values with no stock" do
        first_variant.in_stock_cache = false
        first_variant.save
        expect(subject.for_product(product, true)).to be_empty
      end
    end

  end

end
