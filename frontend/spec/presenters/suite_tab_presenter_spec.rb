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

  describe "#in_stock?" do
    its(:in_stock?) { should eq tab.in_stock_cache }
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

  context "#product_presenter" do
    it "creates a product presenter" do
      product_context = {currency: 'USD', target: target, device: :desktop}
      expect(Spree::ProductPresenter).to receive(:new).with(tab.product, view, product_context)
      subject.product_presenter
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


  context "#lowest_prices" do

    before do
      allow(subject).to receive(:lowest_normal_amount).and_return(BigDecimal.new('21.89'))
    end

    it "returns formatted normal price when no sale price is given" do
     expect(subject.lowest_prices).to eq '<span class="price now" itemprop="price">from $21.89</span>'
    end

    context "with sale price" do

      before do
        allow(subject).to receive(:lowest_sale_amount).and_return(BigDecimal.new('11.99'))
      end

      it "returns formatted normal and sale price" do
        expect(subject.lowest_prices).to eq '<span class="price was" itemprop="price">from $21.89</span><span class="price now">$11.99</span>'
      end
    end
  end


end
