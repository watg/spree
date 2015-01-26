require 'spec_helper'
include Spree::Api::TestingSupport::Helpers

describe Spree::PinterestService do

  let(:suite)   { Spree::Suite.new(target: target) }
  let(:tab)     { Spree::SuiteTab.new(tab_type: 'some-tab-permalink', product: product) }
  let(:product) { Spree::Product.new(name: "My Product", description: "Descipt") }
  let(:variant) { Spree::Variant.new(in_stock_cache: true, number: "V1234") }
  let(:target)  { Spree::Target.new(name: "Women") }

  context 'suites_url' do
    let(:url) { Spree::Core::Engine.routes.url_helpers.suite_url(id: 'suite-perma', tab: 'made-by-the-gang', variant_id: 'V1234') }
    let(:kit_url) { Spree::Core::Engine.routes.url_helpers.suite_url(id: 'suite-perma', tab: 'knit-your-own', variant_id: 'V1234') }

    before do
      suite.tabs << tab
      product.variants_including_master << variant
      variant.current_price_in("GBP").amount = 15.55

      allow(Spree::Suite).to receive(:find_by).with(permalink: 'suite-perma').and_return suite
    end

    it "returns a correct OpenStruct" do
      outcome = Spree::PinterestService.run({url: url})

      expect(outcome).to be_valid

      result = outcome.result
      expect(result.product_id).to eq "V1234"
      expect(result.title).to eq "My Product"
      expect(result.gender).to eq "women"

      expect(result.price).to eq 15.55
      expect(result.description).to eq "Descipt"
      expect(result.currency_code).to eq "GBP"
      expect(result.availability).to eq "in stock"
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


  describe '#gender' do
    it "returns male when target name is Male" do
      expect(subject.send(:gender, Spree::Target.new(name: 'male'))).to eq "male"
    end

    it "returns unisex when target is not supplied" do
      expect(subject.send(:gender, nil)).to eq "unisex"
    end
  end


  describe '#fancy_title' do
    it "returns product name when tab type is not knit-your-own or made-by-the-gang" do
      expect(subject.send(:fancy_title, "My Product", 'something-else')).to eq "My Product"
    end

    it "adds Knit Kit to product name when product is a kit" do
      expect(subject.send(:fancy_title, "My Product", 'knit-your-own')).to eq "My Product Knit Kit"
    end

    it "adds #madeunique by The Gang to product name when product is gang made" do
      expect(subject.send(:fancy_title, "My Product", 'made-by-the-gang')).to eq "My Product #madeunique by The Gang"
    end
  end

  describe "#variant_url" do
    before do
      tab.tab_type = 'made-by-the-gang'
      suite.permalink = 'rainbow-sweater'
    end

    it "fin4ds the suite url" do
      expect(subject.send(:variant_url, suite, tab, variant)).
        to eq 'http://www.example.com/product/rainbow-sweater/made-by-the-gang/V1234'
    end
  end

  context 'validations' do
    it "returns a could_not_parse_url error" do
      url = "invalid_string"
      outcome = Spree::PinterestService.run({url: url})
      expect(outcome.errors[:url]).to eq ["Could not parse url"]
    end

    it "returns a could_not_find_product error" do
      url = "http://www.woolandthegang.com/shop/product/invalid_suite"
      outcome = Spree::PinterestService.run({url: url})
      expect(outcome.errors[:url]).to eq ["Could not find requested product"]
    end
  end

end
