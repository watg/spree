require 'spec_helper'

describe Spree::PinterestService do

  context 'returns a correct OpenStruct response' do 
    let!(:product_page_tab) { create(:product_page_tab) }
    let(:target) { create(:target, name: 'female' ) }
    let(:product_page) { product_page_tab.product_page }
    let(:product) {create(:product_with_variants_displayable)}
    let(:variant) { product.variants.first }
    let(:variant_slug) { variant.option_values.first.name }
    let(:variant_target) { create(:variant_target, variant: variant, target: target ) }
    let(:context) { {context: {tab: product_page_tab.tab_type}} }
    let!(:kit_context) { {context: {tab: Spree::ProductPageTab::KNIT_YOUR_OWN }} }

    before do
      product_page.target = target
      product_page.save
      variant.in_stock_cache = true
      variant.save
    end

    context 'new_url' do

      let(:url) { variant.decorate( context ).url_encoded_product_page_url(product_page.decorate( context )) }
      let(:kit_url) { variant.decorate( kit_context ).url_encoded_product_page_url(product_page.decorate( kit_context ), Spree::ProductPageTab::KNIT_YOUR_OWN) }

      context 'images' do

        let!(:image) { create(:image, viewable: variant_target) }

        it "returns image information" do
          outcome = Spree::PinterestService.run({url: url})
          outcome.result.images.should == [ image ]
        end

      end

      context 'male genger' do
        let(:target) { create(:target, name: 'male' ) }
        it "returns male as target" do
          outcome = Spree::PinterestService.run({url: url})
          outcome.result.gender.should == "male"
        end
      end

      context 'no genger' do
        let(:target) { nil }
        it "returns male as target" do
          outcome = Spree::PinterestService.run({url: url})
          outcome.result.gender.should == "unisex"
        end
      end

      context 'old variant_id' do
        it "reruns the correct details" do
          url2 = url.gsub(variant.number.to_s,variant.id.to_s)
          outcome = Spree::PinterestService.run({url: url2})
          outcome.success?.should == true
          outcome.result.product_id.should == variant.number 
        end

      end

      it "returns a correct OpenStruct response with a product" do
        outcome = Spree::PinterestService.run({url: url})

        outcome.success?.should == true
        outcome.result.product_id.should == variant.number 
        outcome.result.title.should == product.name.to_s + " #madeunique by The Gang"
        outcome.result.gender.should == "female"

        outcome.result.price.should == variant.current_price_in("GBP").amount
        outcome.result.currency_code.should == "GBP"
        outcome.result.availability.should == "in stock"
      end

      it "returns a correct OpenStruct response with a kit" do
        outcome = Spree::PinterestService.run({url: kit_url})

        outcome.success?.should == true
        outcome.result.product_id.should == variant.number
        outcome.result.title.should == product.name.to_s + " Knit Kit"
        outcome.result.gender.should == "female"

        outcome.result.price.should == variant.current_price_in("GBP").amount
        outcome.result.currency_code.should == "GBP"
        outcome.result.availability.should == "in stock"
      end

    end

    context 'old_url' do
      let(:url) {"http://www.woolandthegang.com/shop/products/#{product.slug}/#{variant_slug}"}

      it "returns a correct OpenStruct response with a product" do
        product.marketing_type = create(:marketing_type, category: "rtw")
        product.save!

        outcome = Spree::PinterestService.run({url: url})

        outcome.success?.should == true
        outcome.result.product_id.should == product.slug
        outcome.result.title.should == product.name.to_s + " #madeunique by The Gang"

        outcome.result.price.should == variant.current_price_in("GBP").amount
        outcome.result.currency_code.should == "GBP"
        outcome.result.availability.should == "in stock"
      end

      it "returns a correct OpenStruct response with a kit" do
        product.product_type = create(:product_type_kit)
        product.save!
        Spree::Variant.any_instance.stub :assembly? => true

        outcome = Spree::PinterestService.run({url: url})

        outcome.success?.should == true
        outcome.result.product_id.should == product.slug
        outcome.result.title.should == product.name.to_s + " Knit Kit"

        outcome.result.price.should == variant.current_price_in("GBP").amount
        outcome.result.currency_code.should == "GBP"
        outcome.result.availability.should == "in stock"
      end

    end
  end

  it "returns a could_not_parse_url error" do
    url = "invalid_string"
    outcome = Spree::PinterestService.run({url: url})
    outcome.errors.symbolic[:url].should == :could_not_parse_url
  end

  it "returns a could_not_find_product error" do
    url = "http://www.woolandthegang.com/shop/products/invalid_product/variant_slug"
    outcome = Spree::PinterestService.run({url: url})
    outcome.errors.symbolic[:url].should == :could_not_find_product
  end

end
