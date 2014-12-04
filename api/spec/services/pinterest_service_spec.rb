require 'spec_helper'
include Spree::Api::TestingSupport::Helpers

describe Spree::PinterestService do

  context 'product_page style url' do
    let!(:product_page_tab) { create(:product_page_tab, product: product) }
    let(:target) { create(:target, name: 'female' ) }
    let(:product_page) { product_page_tab.product_page }
    let(:product) {create(:product_with_variants, number_of_variants: 1)}
    let(:variant) { product.variants.first }
    let(:variant_slug) { variant.option_values.first.name }
    let(:variant_target) { create(:variant_target, variant: variant, target: target ) }
    let(:context) { {context: {tab: product_page_tab.tab_type}} }
    let!(:kit_context) { {context: {tab: product_page.knit_your_own }} }

    before do
      product_page.target = target
      product_page.save
      variant.in_stock_cache = true
      variant.save
    end


    let(:url) { variant.decorate( context ).url_encoded_product_page_url(product_page.decorate( context )) }
    let(:kit_url) { variant.decorate( kit_context ).url_encoded_product_page_url(product_page.decorate( kit_context ), product_page.knit_your_own) }

    context "variant missing from url" do

      let(:url) { "http://www.example.com/shop/items/#{product_page.permalink}/made-by-the-gang" }

      it "returns the first variant" do
        outcome = Spree::PinterestService.run({url: url})
        outcome.result.product_id.should == variant.number
      end

    end

    context "tab missing from url" do
      let(:url) { "http://www.example.com/shop/items/#{product_page.permalink}" }

      it "returns the first variant" do
        outcome = Spree::PinterestService.run({url: url})
        outcome.result.product_id.should == variant.number
      end

    end

    it "returns a correct OpenStruct response with a product" do
      outcome = Spree::PinterestService.run({url: url})

      outcome.valid?.should be_true
      outcome.result.product_id.should == variant.number
      outcome.result.title.should == product.name.to_s + " #madeunique by The Gang"
      outcome.result.gender.should == "female"

      outcome.result.price.should == variant.current_price_in("GBP").amount
      outcome.result.currency_code.should == "GBP"
      outcome.result.availability.should == "in stock"
    end

    it "returns a correct OpenStruct response with a kit" do
      outcome = Spree::PinterestService.run({url: kit_url})

      outcome.valid?.should be_true
      outcome.result.product_id.should == variant.number
      outcome.result.title.should == product.name.to_s + " Knit Kit"
      outcome.result.gender.should == "female"

      outcome.result.price.should == variant.current_price_in("GBP").amount
      outcome.result.currency_code.should == "GBP"
      outcome.result.availability.should == "in stock"
    end

  end # end product_page_url test

  context 'suites_url' do
    let(:suite)   { Spree::Suite.new(target: target) }
    let(:tab)     { Spree::SuiteTab.new(tab_type: 'some-tab-permalink', product: product) }
    let(:product) { Spree::Product.new(name: "My Product", description: "Descipt") }
    let(:variant) { Spree::Variant.new(in_stock_cache: true, number: "V1234") }
    let(:target)  { Spree::Target.new(name: "Women") }

    let(:url) { Spree::Core::Engine.routes.url_helpers.suite_url(id: 'suite-perma', tab: 'made-by-the-gang', variant_id: 'V1234') }
    let(:kit_url) { Spree::Core::Engine.routes.url_helpers.suite_url(id: 'suite-perma', tab: 'knit-your-own', variant_id: 'V1234') }

    before do
      suite.tabs << tab
      product.variants_including_master << variant
      variant.current_price_in("GBP").amount = 15.55

      allow(Spree::Suite).to receive(:find_by).with(permalink: 'suite-perma').and_return suite
    end

    it "returns a correct OpenStruct response with a normal product" do
      outcome = Spree::PinterestService.run({url: url})

      expect(outcome).to be_valid

      result = outcome.result
      expect(result.product_id).to eq "V1234"
      expect(result.title).to eq "My Product #madeunique by The Gang"
      expect(result.gender).to eq "women"

      expect(result.price).to eq 15.55
      expect(result.description).to eq "Descipt"
      expect(result.currency_code).to eq "GBP"
      expect(result.availability).to eq "in stock"
    end

    it "returns a correct OpenStruct response with a kit" do
      outcome = Spree::PinterestService.run({url: kit_url})
      expect(outcome.result.title).to eq product.name.to_s + " Knit Kit"
    end
  end


  ## Private methods

  context '#images' do
    let(:variant) { Spree::Variant.new }
    let(:image1) { Spree::Image.new(attachment: image("thinking-cat.jpg")) }

    before do
      variant.images << image1
    end

    it "returns an array of up to 6 image urls" do
      # ["/spree/images//product/thinking-cat.jpg?1415905858"]
      image_urls = subject.send(:images, variant)
      expect(image_urls.size).to eq 1
      expect(image_urls.first).to include('thinking-cat')
    end
  end

  context '#load_suite_tab' do
    let(:suite) { Spree::Suite.new }
    let(:tab1) { Spree::SuiteTab.new(tab_type: 'some-tab-type1') }
    let(:tab2) { Spree::SuiteTab.new(tab_type: 'some-tab-type2') }

    before do
      suite.tabs << tab1
      suite.tabs << tab2
    end

    it "returns the correct tab when tab type is supplied" do
      expect(subject.send(:load_suite_tab, suite, 'some-tab-type2')).to eq tab2
    end

    it "returns the first tab when tab type is invalid" do
      expect(subject.send(:load_suite_tab, suite, 'some-non-existent-tab')).to eq tab1
    end

    it "returns the first tab when tab type is not supplied" do
      expect(subject.send(:load_suite_tab, suite)).to eq tab1
    end
  end


  context '#load_variant' do
    let(:product) { Spree::Product.new }
    let(:variant1) { Spree::Variant.new(number: 'V1', is_master: true) }
    let(:variant2) { Spree::Variant.new(number: 'V2') }

    before do
      product.variants_including_master << variant1
      product.variants_including_master << variant2
    end

    it "returns the correct variant when variant type is supplied" do
      expect(subject.send(:load_variant, product, 'V2')).to eq variant2
    end

    it "returns the first variant when variant type is invalid" do
      expect(subject.send(:load_variant, product, 'some-non-existent-variant')).to eq variant1
    end

    it "returns the first variant when variant type is not supplied" do
      expect(subject.send(:load_variant, product)).to eq variant1
    end
  end


  context '#gender' do
    it "returns male when target name is Male" do
      expect(subject.send(:gender, Spree::Target.new(name: 'male'))).to eq "male"
    end

    it "returns unisex when target is not supplied" do
      expect(subject.send(:gender, nil)).to eq "unisex"
    end
  end


  context 'validations' do
    it "returns a could_not_parse_url error" do
      url = "invalid_string"
      outcome = Spree::PinterestService.run({url: url})
      outcome.errors[:url].should == ["Could not parse url"]
    end

    it "returns a could_not_find_product error" do
      url = "http://www.woolandthegang.com/shop/product/invalid_suite"
      outcome = Spree::PinterestService.run({url: url})
      outcome.errors[:url].should == ["Could not find requested product"]
    end
  end

end
