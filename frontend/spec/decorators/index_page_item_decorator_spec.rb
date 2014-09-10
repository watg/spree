require 'spec_helper'

describe Spree::IndexPageItemDecorator, type: :decorator do
  include Draper::ViewHelpers

  let(:index_page_item) { create(:index_page_item) }
  let(:product_page) { index_page_item.product_page }
  let(:currency) { "USD" }
  let(:context) { {context: {current_currency: currency}} }
  subject { index_page_item.decorate(context) }


  describe "#image_url" do
    context "with an image" do
      before :each do
        attachment = double(url: "the image url")
        image = double(attachment: attachment)
        allow(index_page_item).to receive(:image).and_return(image)
      end

      its(:image_url) { should eq("the image url") }
    end

    context "without an image" do
      its(:image_url) { should eq("/assets/product-group/placeholder-470x600.gif") }
    end
  end

  describe "#made_by_the_gang_link?" do

    context "with displayed_variants with stock on the product page" do
      before :each do
        product_page.displayed_variants << create(:variant_with_stock_items)
      end

      its(:made_by_the_gang_link?) { should be_true }
    end

    context "with displayed_variants without stock on the product page" do
      let(:variant) { create(:variant, in_stock_cache: false) }

      before :each do
        product_page.displayed_variants << variant
      end

      its(:made_by_the_gang_link?) { should be_false }
    end

    context "without displayed_variants on the product page" do
      its(:made_by_the_gang_link?) { should be_false }
    end

  end

  describe "#made_by_the_gang_url" do
    let(:made_by_the_gang_url) { spree.product_page_path(product_page, tab: "made-by-the-gang") }
    let(:variant) { create(:variant, in_stock_cache: true) }
    let(:made_by_the_gang_url_with_variant) { spree.product_page_path(product_page, tab: "made-by-the-gang", variant_id: variant.id) }

    before :each do
      allow(helpers).to receive(:product_page_path).
        with(id: product_page.permalink, tab: "made-by-the-gang", variant_id: nil).and_return(made_by_the_gang_url)
    end

    its(:made_by_the_gang_url) { should eq(made_by_the_gang_url) }
  end

  describe "made by the gang prices" do

    let(:product) { create(:product_with_prices) }
    let(:product2) { create(:product_with_stock_and_prices, usd_price: 3.00, gbp_price: 7.50) }
    let(:variant) { create(:variant, in_sale: true, in_stock_cache: true) }

    before :each do
      create(:price, variant: variant, price: 2.99, sale: true)

      _sale_price = create(:price, sale: true, amount: 2.00, currency: 'USD', variant: product2.master )
      product2.master.update_attributes(in_sale: true)

      [product,product2].each do |p|
        product_page.displayed_variants << p.master
      end
    end

    it "does not returns out-of-stock from prices with a variant with no stock but " do
      variant.in_stock_cache = false
      variant.save
      index_page_item.variant = variant
      expect(subject.made_by_the_gang_prices).to eq '<span class="price was" itemprop="price">from $3.00</span><span class="price now">$2.00</span>'
    end

    it "returns sale and normal prices without a variant" do
      expect(subject.made_by_the_gang_prices).to eq '<span class="price was" itemprop="price">from $3.00</span><span class="price now">$2.00</span>'
    end

    it "returns out-of-stock when no stock" do
      [product,product2].each { |p| p.master.in_stock_cache = false; p.master.save  }
      expect(subject.made_by_the_gang_prices).to eq '<span class="price" itemprop="price">out-of-stock</span>'
    end

    it "returns sale and normal prices without a variant" do
      index_page_item.variant = nil
      expect(subject.made_by_the_gang_prices).to eq "<span class=\"price was\" itemprop=\"price\">from $3.00</span><span class=\"price now\">$2.00</span>"
    end

  end

  describe "#knit_your_own_link?" do

    context "with a kit product on the product page" do
      let(:kit) { create(:product, product_type: create(:product_type_kit)) }
      let!(:variant) { create(:variant, product: kit, price: 9.99, in_sale: true, in_stock_cache: true) }
      let(:tab) { product_page.knit_your_own }

      before :each do
        product_page.product_groups << kit.product_group
        tab.product = kit
        tab.save!
      end

      context "has_stock" do
        its(:knit_your_own_link?) { should be_true }
      end

      context "has_no_stock" do
        before { kit.variants.each { |v| v.in_stock_cache = false; v.save } }
        its(:knit_your_own_link?) { should be_false }
      end

    end

    context "without a kit product on the product page" do
      its(:knit_your_own_link?) { should be_false }
    end

  end

  describe "#knit_your_own_url" do
    let(:knit_your_own_url) { spree.product_page_path(product_page, tab: "knit-your-own") }
    let(:variant) { create(:variant) }
    let(:knit_your_own_url_with_variant) { spree.product_page_path(product_page, tab: "knit-your-own", variant_id: variant.id) }

    context "with a variant" do
      before :each do
        index_page_item.variant = variant
        allow(helpers).to receive(:product_page_path).
          with(id: product_page.permalink, tab: "knit-your-own", variant_id: variant.id).and_return(knit_your_own_url_with_variant)
      end

      its(:knit_your_own_url) { should eq(knit_your_own_url_with_variant) }
    end

    context "without a variant" do
      before :each do
        allow(helpers).to receive(:product_page_path).
          with(id: product_page.permalink, tab: "knit-your-own", variant_id: nil).and_return(knit_your_own_url)
      end

      its(:knit_your_own_url) { should eq(knit_your_own_url) }
    end
  end


  describe "knit your own prices" do

    let(:kit) { create(:base_product) }
    let!(:kit_variant) { create(:variant, product: kit,  in_sale: true, in_stock_cache: true) }
    let!(:kit_variant2) { create(:variant, product: kit, in_sale: true, in_stock_cache: true) }
    let!(:kit_variant3) { create(:variant, product: kit, in_stock_cache: false) }
    let(:tab) { subject.product_page.knit_your_own }

    before :each do
      create(:price, variant: kit_variant, price: 2.99, sale: true)
      create(:price, variant: kit_variant2, price: 2.00, sale: true)
      tab.product = kit
      tab.save!
    end

    context "Dyanmic Kit" do

      let(:dynamic_kit) { create(:base_product, price: 5.00, name: 'dynamic kit') }
      let!(:assembly_definition) { create(:assembly_definition, variant: dynamic_kit.master) }

      before do
        tab.product = dynamic_kit.reload
        dynamic_kit.master.update_column(:in_stock_cache, true)
        tab.save!
      end

      it "returns a normal price" do
        expect(subject.knit_your_own_prices).to eq '<span class="price now" itemprop="price">from $5.00</span>'
      end

      it "returns a sale price" do
        dynamic_kit.master.in_sale = true
        dynamic_kit.save
        create(:price, variant: dynamic_kit.master, price: 1.23, sale: true)
        expect(subject.knit_your_own_prices).to eq '<span class="price was" itemprop="price">from $5.00</span><span class="price now">$1.23</span>'
      end

    end

    it "returns sale and normal from prices with a variant" do
      expect(subject.knit_your_own_prices).to eq '<span class="price was" itemprop="price">from $19.99</span><span class="price now">$2.00</span>'
    end


    it "returns sale and normal from prices with a variant" do
      index_page_item.variant = kit_variant
      expect(subject.knit_your_own_prices).to eq '<span class="price was" itemprop="price">from $19.99</span><span class="price now">$2.00</span>'
    end

    it "returns out-of-stock from prices with a variant with no stock" do
      kit.variants.each { |k| k.in_stock_cache = false; k.save }
      kit_variant.in_stock_cache = false
      index_page_item.variant = kit_variant
      expect(subject.knit_your_own_prices).to eq '<span class="price" itemprop="price">out-of-stock</span>'
    end

    it "returns out-of-stock from prices without a variant and no stock" do
      kit.variants.each { |k| k.in_stock_cache = false; k.save }
      expect(subject.knit_your_own_prices).to eq '<span class="price" itemprop="price">out-of-stock</span>'
    end

    it "returns sale and normal prices without a variant" do
      index_page_item.variant = nil
      expect(subject.knit_your_own_prices).to eq "<span class=\"price was\" itemprop=\"price\">from $19.99</span><span class=\"price now\">$2.00</span>"
    end

  end
end
