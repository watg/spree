require 'spec_helper'

# There is a duplication of tests with the Base Feed Job Spec,
# but keep to prevent regression.

describe Spree::PolyvorFeedJob do

  let(:currency) { 'USD' }
  let(:target) { build(:target, name: 'Women' ) }
  let(:suite) { build(:suite, target: target) }
  let(:tab) { Spree::SuiteTab.new(suite: suite) }

  let(:product) { Spree::Product.new }
  let(:variant) { Spree::Variant.new(id: 12, product: product) }

  describe '#header' do
    it "contains the header array" do
      expect(subject.send(:header)).to be_kind_of(Array)
    end
  end

  describe '#feed' do
    it 'generates a csv file' do
      parsed_csv = CSV.parse(subject.feed, col_sep: "\t")

      expect(parsed_csv).to be_kind_of Array
      expect(parsed_csv.size).to eq 1
      expect(parsed_csv[0]).to eq subject.send(:header)
    end
  end

  describe '#format_csv' do

    before do
      variant.price_normal_in(currency).amount = 8.99

      suite.target.name = 'Women'
      suite.name = 'Tala Tank'
    end

    it 'creates a a correctly formatted file' do
      expected_csv = [
        "Tala Tank",
        "Wool and the Gang",
        "http://www.example.com/product/#{suite.permalink}",
        nil,
        nil, #image url
        BigDecimal.new('8.99'),
        8.99,
        "USD",
        "",
        nil, #colour
        nil,
        nil,
        "Women",
        "Clothing",
        nil
      ]

      formatted_csv = subject.send(:format_csv, suite, tab, product, variant)
      expect(formatted_csv).to eq expected_csv
      expect(formatted_csv.size).to eq subject.send(:header).size
    end
  end

  describe '#gender' do
    it "returns 'Women' for target Women" do
      expect(subject.send(:gender, suite)).to eq 'Women'
    end

    it "returns 'Men' for target Men" do
      target.name = "Men"
      expect(subject.send(:gender, suite)).to eq 'Men'
    end

    it "returns 'Unisex' when target is not supplied" do
      suite.target = nil
      expect(subject.send(:gender, suite)).to eq 'Unisex'
    end
  end

  describe "#variant_image_url" do
    let(:image) { Spree::Image.new }

    context 'image on variant' do
      before do
        allow(variant).to receive(:images_for).with(target).and_return [image]
        image.stub_chain(:attachment, :url).and_return('image-url')
      end

      it "returns image on variant" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq 'image-url'
      end
    end

    context 'when no image on variant' do
      before do
        allow(product).to receive(:images_for).with(target).and_return [image]
        image.stub_chain(:attachment, :url).and_return('image-url-on-product')
      end

      it "finds image url on product" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq 'image-url-on-product'
      end
    end

    context 'when there is no image on variant and product' do
      let(:suite_tab_image) { Spree::SuiteTabImage.new }
      before do
        tab.image = suite_tab_image
        suite_tab_image.stub_chain(:attachment, :url).and_return('image-url-on-tab')
      end

      it "finds image on tab" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq 'image-url-on-tab'
      end
    end

    context 'when image not found on variant, product or tab' do
      before do
        variant.stub(images_for: [])
        variant.stub_chain(:product, :images_for).and_return([])
        tab.stub(image: nil)
      end
      it "if found no where else, returns default image" do
        expect(subject.send(:variant_image_url, variant, suite, tab)).to eq Spree::PolyvorFeedJob::DEFAULT_IMAGE_URL
      end
    end
  end
end
