require 'spec_helper'

describe Spree::SuiteTabPresenter do

  let(:target) { mock_model(Spree::Target)}
  let(:suite) { Spree::Suite.new(permalink: 'suite-permalink') }
  let(:tab) { Spree::SuiteTab.new(suite: suite, tab_type: 'knit-your-own') }
  let(:context) { { currency: 'USD', target: target, suite: suite, device: :desktop}}
  subject { described_class.new(tab, view, context) }

  before { allow(view).to receive(:current_currency).and_return 'USD' }

  context "#product" do
    its(:product) { should eq tab.product }
  end

  context "#id" do
    its(:id) { should eq tab.id }
  end

  describe "#ready_made?" do
    let(:suite) { Spree::Suite.new(permalink: 'suite-permalink') }
    let(:other_tab) { Spree::SuiteTab.new(suite: suite, tab_type: 'knit-your-own') }
    let(:ready_made_tab) { Spree::SuiteTab.new(suite: suite, tab_type: 'made-by-the-gang') }

    let!(:ready_made_presenter) { described_class.new(ready_made_tab, view, context) }
    let!(:other_presenter) { described_class.new(other_tab, view, context) }

    it "should return true if tab is of type made-by-the-gang" do
      expect(ready_made_presenter.ready_made?).to be_truthy
    end
    it "should return false if tab is not of type made-by-the-gang" do
      expect(other_presenter.ready_made?).to be_falsey
    end
  end

  describe "#in_stock?" do
    its(:in_stock?) { should eq tab.in_stock_cache }
  end

  describe "variants_total_on_hand" do
    let(:product) { Spree::Product.new }
    let(:variant_1) { Spree::Variant.new }
    let(:variant_2) { Spree::Variant.new }

    before do
      tab.product = product
      product.variants = [variant_1, variant_2]

      mock_quantifier_1 = double(total_on_hand: 2)
      allow(Spree::Stock::Quantifier).to receive(:new).with(variant_1).and_return(mock_quantifier_1)

      mock_quantifier_2 = double(total_on_hand: 3)
      allow(Spree::Stock::Quantifier).to receive(:new).with(variant_2).and_return(mock_quantifier_2)
    end

    it "should return a data structure of variants and total on hand" do
      expected = {
        variant_1.number => 2,
        variant_2.number => 3
      }
      expect(subject.variants_total_on_hand).to eq expected
    end

    context "count on hand above 5" do

      before do
        mock_quantifier_1 = double(total_on_hand: 5)
        allow(Spree::Stock::Quantifier).to receive(:new).with(variant_1).and_return(mock_quantifier_1)

        mock_quantifier_2 = double(total_on_hand: 6)
        allow(Spree::Stock::Quantifier).to receive(:new).with(variant_2).and_return(mock_quantifier_2)
      end

      it "only includes variants with 5 or fewer in stock" do
        expected = {
          variant_1.number => 5
        }
        expect(subject.variants_total_on_hand).to eq expected
      end

    end

    context "count on hand less than 1" do

      before do
        mock_quantifier_1 = double(total_on_hand: 1)
        allow(Spree::Stock::Quantifier).to receive(:new).with(variant_1).and_return(mock_quantifier_1)

        mock_quantifier_2 = double(total_on_hand: 0)
        allow(Spree::Stock::Quantifier).to receive(:new).with(variant_2).and_return(mock_quantifier_2)
      end

      it "should return a data structure of variants and total on hand" do
        expected = {
          variant_1.number => 1
        }
        expect(subject.variants_total_on_hand).to eq expected
      end

    end

  end

  context "#tab_type" do
    its(:tab_type) { should eq tab.tab_type }
  end

  describe "#cart_partial" do
    its(:cart_partial) { should eq 'spree/suites/tab_type/knit_your_own' }

    context "made-by-the-gang" do
      before { tab.tab_type = 'made-by-the-gang' }
      its(:cart_partial) { should eq 'spree/suites/tab_type/default' }
    end

    context "default" do
      before { tab.tab_type = 'default' }
      its(:cart_partial) { should eq 'spree/suites/tab_type/default' }
    end

  end

  context "#link_to" do
    it "links to a suite and a tab" do
      expect(subject.link_to).to eq spree.suite_url('suite-permalink', tab: 'knit-your-own')
    end

    context "default" do
      before { tab.tab_type = 'default' }

      it "links to a suite and no tab" do
        expect(subject.link_to).to eq spree.suite_url('suite-permalink', tab: 'default')
      end
    end

  end

  context "#banner_url" do

    let(:url) { 'the image url'}
    let(:attachment) { double(url: url) }
    let(:image) { double(attachment: attachment, alt: 'wooo') }
    let(:device) { :desktop }

    its(:banner_url) { should be_nil }

    context "with image" do
      before do
        allow(tab).to receive(:image).and_return(image)
      end

      its(:banner_url) { should eq url}

      it "should receive an attachment style request for large" do
        expect(attachment).to receive(:url).with(:large)
        subject.banner_url
      end

      context 'mobile' do
        before { context[:device] = :mobile }

        it 'should receive an attachement style request for mobile' do
          expect(attachment).to receive(:url).with(:mobile)
          subject.banner_url
        end
      end

    end

  end

  describe "#inverted_colour" do

    it "should be nil when position is odd" do
      tab.position = 1
      expect(subject.inverted_colour).to eq nil
    end

    it "should be 'inverted' when position is even" do
      tab.position = 2
      expect(subject.inverted_colour).to eq 'inverted'
    end

  end

  context "social_links" do
    before { suite.title = 'foobar' }
    context "#twitter_url" do

      it "returns the correct link" do
        text = "Presenting foobar by Wool and the Gang: #{spree.suite_url('suite-permalink', tab: 'knit-your-own')}"
        encoded_text = subject.send(:url_encode, text)
        expect(subject.twitter_url).to eq "http://twitter.com/intent/tweet?text=#{encoded_text}"
      end
    end

    context "#facebook_url" do
      it "returns the correct link" do
        link_to = spree.suite_url('suite-permalink', tab: 'knit-your-own')
        encoded_link_to = subject.send(:url_encode, link_to)
        expect(subject.facebook_url).to eq "http://facebook.com/sharer/sharer.php?u=#{encoded_link_to}"
      end
    end

    context "#pinterest_url" do

      its(:pinterest_url) do
        text = "Presenting foobar by Wool and the Gang"
        encoded_text = subject.send(:url_encode, text)
        link_to = spree.suite_url('suite-permalink', tab: 'knit-your-own')
        encoded_link_to = subject.send(:url_encode, link_to)

        expect(subject.pinterest_url).to eq "http://pinterest.com/pin/create/%20button/?url=#{encoded_link_to}&amp;media=&amp;description=#{encoded_text}"
      end
    end
  end

  describe "#meta_name" do

    it "returns the name of the suite" do
      expect(subject.meta_name).to eq subject.suite.name
    end

  end

  describe "#meta_description" do

    before do
      long_sentance = []
      16.times { long_sentance << '1234567890' }
      long_sentance = long_sentance.join(' ')

      mock_product = mock_model(Spree::Product, description: long_sentance)
      allow(subject).to receive(:product).and_return(mock_product)
    end


    it "returns the description of the product" do
      expect(subject.meta_description.size).to eq 156
      expect(subject.meta_description.split(' ').last).to eq '1234567890...'
    end

  end

  describe "meta_title" do

    let(:marketing_type) { Spree::MarketingType.new(title: 'title', meta_title: "meta_title")}
    let(:product) { Spree::Product.new(marketing_type: marketing_type)}

    before do
      subject.suite_tab.product = product
      suite.title = 'suite_title'
    end

    it "returns the title" do
      expected = "suite_title | meta_title | WOOL AND THE GANG"
      expect(subject.meta_title).to eq expected
    end

    context "suite has a meta_title" do

      before do
        subject.suite.meta_title = 'ralf'
      end

      it "returns the title" do
        expected = "ralf | meta_title | WOOL AND THE GANG"
        expect(subject.meta_title).to eq expected
      end

    end

    context "no marketing type meta title" do

      before do
        marketing_type.meta_title = nil
      end

      it "returns the title" do
        expected = "suite_title | title | WOOL AND THE GANG"
        expect(subject.meta_title).to eq expected
      end
    end

  end


  describe "meta_keywords" do

    let(:marketing_type) { Spree::MarketingType.new(title: 'marketing_type', meta_title: "meta_title")}
    let(:product) { Spree::Product.new(meta_keywords: 'product', marketing_type: marketing_type)}

    before do
      subject.suite_tab.product = product
      suite.title = 'suite_title'
    end

    it "returns the keywords of the product" do
      expected = "Knitwear, Knitting, Knitted, Wool, Unique, Handmade, Sustainable yarn, How to knit, Learn to knit, suite_title, marketing_type, product"
      expect(subject.meta_keywords).to eq expected
    end
  end

  context "#lowest_prices" do

    before do
      allow(subject).to receive(:lowest_normal_amount).and_return(BigDecimal.new('21.89'))
    end

    it "returns formatted normal price when no sale price is given" do
     expect(subject.lowest_prices).to eq '<span class="price now" itemprop="price">from $21.89</span>'
    end

    context "with sale price" do

      before do
        tab.in_sale_cache = true
        allow(subject).to receive(:lowest_sale_amount).and_return(BigDecimal.new('11.99'))
      end

      it "returns formatted normal and sale price" do
        expect(subject.lowest_prices).to eq '<span class="price was" itemprop="price">from $21.89</span><span class="price now">from $11.99</span>'
      end

      context "sale price disabled" do

        before do
          tab.in_sale_cache = false
        end

        it "returns formatted normal and sale price" do
          expect(subject.lowest_prices).to eq '<span class="price now" itemprop="price">from $21.89</span>'
        end

      end

    end
  end

  describe "#cross_sales_heading" do

    context "when tab type is yarn-and-wool" do

      before { tab.tab_type = 'yarn-and-wool' }
      it "returns correct heading" do
        expect(subject.cross_sales_heading).to eq 'What you can make'
      end
    end

    context "when tab type is knitting-pattern" do

      before { tab.tab_type = 'knitting-pattern' }
      it "returns correct heading" do
        expect(subject.cross_sales_heading).to eq 'Knit this pattern'
      end
    end

    context "when tab type is made-by-the-gang" do

      before { tab.tab_type = 'made-by-the-gang' }
      it "returns correct heading" do
        expect(subject.cross_sales_heading).to eq 'More ready made goodness'
      end
    end

    context "when tab type is anything else" do
      it "returns correct heading" do
        expect(subject.cross_sales_heading).to eq 'More WATG goodness'
      end
    end
  end

end
