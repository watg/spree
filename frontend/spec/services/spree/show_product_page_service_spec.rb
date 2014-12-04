require 'spec_helper'

describe Spree::ShowProductPageService do
  subject { Spree::ShowProductPageService }

  #let(:product_page) { product_page_tab.product_page.decorate }
  let(:product_page) { create(:product_page).decorate }
  let(:product_page_tab_kit) { product_page.knit_your_own }
  let(:product_page_tab) { product_page.made_by_the_gang }
  let(:variant) { build(:variant, in_stock_cache: 1) }

  before do
    variant.in_stock_cache = true
    variant.save
  end

  context "errors" do

    it "should return a list of errors" do
      outcome = subject.run( permalink: 123123, tab: 'made-by-the-gang', currency: nil, request: 'foo' )
      expect(outcome.errors.message_list).to eq(["Currency can't be nil"])
    end

  end

  context "selected variant" do
    let(:variant) { create(:base_variant) }

    it "returns the selected variant when a variant id is supplied and is an id" do
      outcome = subject.run( permalink: product_page.permalink, tab: 'made-by-the-gang', currency: 'GBP', request: 'foo', variant_id: variant.id  )
      expect(outcome.result[:redirect_to]).to be_nil# eq('')
      expect(outcome.result[:decorated_product_page]).to eq(product_page)
      expect(outcome.result[:decorated_product_page].selected_variant).to eq(variant)
    end

    it "returns the selected variant when a variant id is supplied and is a number" do
      outcome = subject.run( permalink: product_page.permalink, tab: 'made-by-the-gang', currency: 'GBP', request: 'foo', variant_id: variant.number  )
      expect(outcome.result[:redirect_to]).to be_nil# eq('')
      expect(outcome.result[:decorated_product_page]).to eq(product_page)
      expect(outcome.result[:decorated_product_page].selected_variant).to eq(variant)
    end

    it "does not return a selected variant with invalid variant id" do
      outcome = subject.run( permalink: product_page.permalink, tab: 'made-by-the-gang', currency: 'GBP', request: 'foo', variant_id: '53'  )
      expect(outcome.result[:decorated_product_page]).to eq(product_page)
      expect(outcome.result[:decorated_product_page].selected_variant).to be_nil
    end

    it "does not return a selected variant with no stock" do
      variant.in_stock_cache = false
      variant.save
      outcome = subject.run( permalink: product_page.permalink, tab: 'made-by-the-gang', currency: 'GBP', request: 'foo', variant_id: variant.number  )
      expect(outcome.result[:redirect_to]).to be_nil
      expect(outcome.result[:decorated_product_page]).to eq(product_page)
      expect(outcome.result[:decorated_product_page].selected_variant).to be_nil
    end

  end

  context "made-by-that-gang" do

    it "is successful with correct tab" do
      outcome = subject.run( permalink: product_page.permalink, tab: 'made-by-the-gang', currency: 'GBP', request: 'foo'  )
      expect(outcome.result[:redirect_to]).to be_nil
      expect(outcome.result[:decorated_product_page]).to eq(product_page)
      expect(outcome.result[:decorated_product_page].selected_tab).to eq(product_page_tab)
    end

    it "should provide a redirect if not a valid permalink" do
      outcome = subject.run( permalink: product_page.permalink, tab: 'foobar', currency: 'GBP', request: 'foo'  )
      expect(outcome.result[:redirect_to]).to eq("/shop/items/#{product_page.permalink}/made-by-the-gang")
      expect(outcome.result[:decorated_product_page]).to be_nil
    end

    it "should redirect back to the shope if a valid product_page can not be found" do
      outcome = subject.run( permalink: 'asdasd', tab: 'made-by-the-gang', currency: 'GBP', request: 'foo'  )
      expect(outcome.result[:redirect_to]).to eq '/'
      expect(outcome.result[:decorated_product_page]).to be_nil
    end
  end

  context "knit-your-own" do

    it "is successful with correct tab" do
      outcome = subject.run( permalink: product_page.permalink, tab: 'knit-your-own', currency: 'GBP', request: 'foo'  )
      expect(outcome.result[:redirect_to]).to be_nil# eq('')
      expect(outcome.result[:decorated_product_page]).to eq(product_page)
      expect(outcome.result[:decorated_product_page].selected_tab).to eq(product_page_tab_kit)
    end

  end

  context "Product Page with no tabs ( e.g. pattern )" do

    it "is successful with no tab" do
      outcome = subject.run( permalink: product_page.permalink, tab: nil, currency: 'GBP', request: 'foo'  )
      expect(outcome.result[:redirect_to]).to eq("/shop/items/#{product_page.permalink}/made-by-the-gang")
      expect(outcome.result[:decorated_product_page]).to be_nil
    end

    it "get redirected with garbled tab" do
      outcome = subject.run( permalink: product_page.permalink, tab: 'asdasd', currency: 'GBP', request: 'foo'  )
      expect(outcome.result[:redirect_to]).to eq("/shop/items/#{product_page.permalink}/made-by-the-gang")
      expect(outcome.result[:decorated_product_page]).to be_nil
    end

  end


end

