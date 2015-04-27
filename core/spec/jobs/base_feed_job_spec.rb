require 'spec_helper'

describe Spree::BaseFeedJob do

  let(:currency) { 'USD' }
  let(:target) { build(:target, name: 'Women' ) }
  let(:suite) { build(:suite, target: target) }
  let(:tab) { Spree::SuiteTab.new(suite: suite) }

  let(:product) { Spree::Product.new }
  let(:variant) { Spree::Variant.new(id: 12, product: product, number: 'N567') }


  ## Config & Storage methods

  describe "#notify" do
    before { Delayed::Worker.delay_jobs = false }
    after { Delayed::Worker.delay_jobs = true }

    it 'sends a notification if a product cannot be added to feed' do
      expect {
        subject.send(:notify, 'oh no!')
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end


  ## Suite, Product & Variant accessor methods

  describe "#all_variants" do
    before do
      suite.tabs << tab
      tab.product = product
      product.variants_including_master << variant
      allow(subject).to receive(:all_suites).and_return [suite]
    end

    it "loads all variants along with their products, suites and tabs in a yield block" do
      expect { |b| subject.send(:all_variants, &b) }.to yield_with_args(suite, tab, product, variant)
    end
  end

  describe "#all_suites" do
    it "loads all suites along with their tabs, products and variants" do
      suite = create(:suite)
      expect(subject.send(:all_suites)).to eq [suite]
    end
  end

  describe "#current_price" do
    before do
      variant.price_normal_in(currency).amount = 6.25
      variant.price_normal_sale_in(currency).amount = 5.21
    end

    it "returns normal price when variant is not in sale" do
      expect(subject.send(:current_price, variant)).to eq 6.25
    end

    it "returns sale price when variant is in sale" do
      variant.in_sale = true
      expect(subject.send(:current_price, variant)).to eq 5.21
    end
  end

  describe "#colour" do
    let(:option_type) { Spree::OptionType.new(presentation: 'Colour') }
    let(:option_value) { Spree::OptionValue.new(presentation: 'blue/yellow', option_type: option_type) }

    it "detects an option type's colour when one is present" do
      variant.option_values << option_value
      expect(subject.send(:colour, variant)).to eq 'blue/yellow'
    end

    it "returns nothing when an option type's colour is not present" do
      expect(subject.send(:colour, variant)).to eq nil
    end
  end

  describe "#size" do
    let(:option_type) { Spree::OptionType.new(presentation: 'Size') }
    let(:option_value) { Spree::OptionValue.new(presentation: 'xl', option_type: option_type) }

    it "detects an option type's size when one is present" do
      variant.option_values << option_value
      expect(subject.send(:size, variant)).to eq 'xl'
    end

    it "returns nothing when an option type's size is not present" do
      expect(subject.send(:size, variant)).to eq nil
    end
  end

  describe "#variant_url" do
    before do
      tab.tab_type = 'made-by-the-gang'
      suite.permalink = 'rainbow-sweater'
    end

    it "finds the suite url" do
      expect(subject.send(:variant_url, suite, tab, variant)).to eq 'http://www.example.com/product/rainbow-sweater/made-by-the-gang/N567'
    end
  end

  describe "#variant_image_url" do
    let(:image) { Spree::Image.new }

    context 'image on variant' do
      before do
        allow(variant).to receive(:images_for).with(target).and_return [image]
        allow(image).to receive_message_chain(:attachment, :url).and_return('image-url')
      end

      it "returns image on variant" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq 'image-url'
      end
    end

    context 'when no image on variant' do
      before do
        allow(product).to receive(:images_for).with(target).and_return [image]
        allow(image).to receive_message_chain(:attachment, :url).and_return('image-url-on-product')
      end

      it "finds image url on product" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq 'image-url-on-product'
      end
    end

    context 'when there is no image on variant and product' do
      let(:suite_tab_image) { Spree::SuiteTabImage.new }
      before do
        tab.image = suite_tab_image
        allow(suite_tab_image).to receive_message_chain(:attachment, :url).and_return('image-url-on-tab')
      end

      it "finds image on tab" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq 'image-url-on-tab'
      end
    end

    context 'when image not found on variant, product or tab' do
      before do
        allow(variant).to receive_messages(images_for: [])
        allow(variant).to receive_message_chain(:product, :images_for).and_return([])
        allow(tab).to receive_messages(image: nil)
      end
      it "if found no where else, returns default image" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq Spree::BaseFeedJob::DEFAULT_IMAGE_URL
      end
    end
  end
end
