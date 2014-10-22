require 'spec_helper'

describe Spree::PolyvorFeedJob do

context
  describe '#header' do
    it "contains the header array" do
      expect(subject.send(:header)).to be_kind_of(Array)
    end
  end

  describe '#feed' do
    it 'generates a csv file' do
      mock_csv = []
      expect(CSV).to receive(:generate).and_return(mock_csv)
      subject.send(:feed)
    end
  end

  describe '#format_csv' do
    before do
      subject.stub(:find_product_page_url => "variant-url.com")
      product_page.target.name = 'Female'
      product_page.name = 'Tala Tank'
    end

    let(:tab) { create(:product_page_tab) }
    let(:target) { create(:target, name: 'female' ) }
    let(:product_page) { tab.product_page }
    let(:product) {create(:product_with_variants_displayable)}
    let(:variant) { product.variants.first }

    it 'creates a a correctly formatted file' do
      expected_csv = ["Tala Tank",
        "Wool and the Gang",
        "variant-url.com",
        nil,
        nil,
        BigDecimal.new('19.99'),
        nil,
        "USD",
        "",
        "Hot Pink", nil, nil,
        "Female",
        "Clothing",
        nil]

      expect(subject.send(:format_csv, product_page, tab, product, variant)).to eq expected_csv
    end
  end

  describe "#notification" do
    before { Delayed::Worker.delay_jobs = false }
    after { Delayed::Worker.delay_jobs = true }

    it 'sends a notification if a product cannot be added to feed' do
      expect {
        subject.send(:notify, 'oh no!')
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  describe "#subject" do
    let(:target) {create(:target, name: 'aliens')}
    let(:product_page) {create(:product_page, target: target)}
    let(:no_target) {create(:product_page, target: nil)}

    it "extracts target or returns 'unknown'" do
      expect(subject.send(:target, product_page)).to eq 'Aliens'
      expect(subject.send(:target, no_target)).to eq "Unknown"
    end
  end

  describe "#sale price" do

    let(:variant) {create(:base_variant)}
    let(:sale_variant) {create(:variant_in_sale)}

    it "finds a sale price of an item if applicable" do
      expect(subject.send(:sale_price, variant)).to eq nil
      expect(subject.send(:sale_price, sale_variant)).to eq 6
    end
  end

  describe "#safe colour" do
    let(:variant) {mock_model(Spree::Variant)}
    let(:option_value) {mock_model(Spree::OptionValue, presentation: 'foobar')}

    let(:variant_with_no_color) {mock_model(Spree::Variant)}
    let(:option_value_with_no_color) {mock_model(Spree::OptionValue)}

    before do
      option_value.stub_chain([:option_type, :is_color?], true)
      variant.stub(option_values: [option_value])

      option_value_with_no_color.stub_chain([:option_type, :is_color?], false)
      variant_with_no_color.stub(option_values: [option_value_with_no_color])
    end

    it "detects an option type's color" do
      expect(subject.send(:safe_colour, variant)).to eq 'foobar'
      expect(subject.send(:safe_colour, variant_with_no_color)).to eq nil
    end
  end

  describe "#find_product_page_url" do
    let(:variant) {mock_model(Spree::Variant)}
    let(:product_page) {create(:product_page)}
    let(:tab) {[double]}

    before do
      tab.stub(url_safe_tab_type: 'made-by-the-gang')
      variant.stub(id: 12)
      variant.stub(is_master?: nil)
      product_page.stub(permalink: 'rainbow-sweater')
    end
    it "find the product page url" do
      expect(subject.send(:find_product_page_url, product_page, tab, variant)).to eq 'http://www.example.com/shop/items/rainbow-sweater/made-by-the-gang/12'
    end
  end

  describe "#variant_image_url" do

    let(:variant) {create(:variant)}
    let(:product_page) {create(:product_page)}
    let(:tab) {[double]}
    let(:image) { mock_model(Spree::Image) }


    context 'image on variant' do
      before do
        variant.stub(images_for: ([image]))
        image.stub_chain(:attachment, :url).and_return('image-url')
      end

      it "returns image on variant" do
        expect(subject.send(:variant_image_url, variant, product_page, tab)).to eq 'image-url'
      end
    end

    context 'when no image on variant' do
      before do
        variant.stub(images_for: [])
        variant.stub_chain(:product, :images_for).and_return([image])
        image.stub_chain(:attachment, :url).and_return('image-url-on-product')
      end

      it "finds image url on product" do
        expect(subject.send(:variant_image_url, variant, product_page, tab)).to eq 'image-url-on-product'
      end
    end

    context 'when n image on variant and product' do
      before do
        variant.stub(images_for: [])
        variant.stub_chain(:product, :images_for).and_return([])
        tab.stub(image: image)
        image.stub_chain(:attachment, :url).and_return('image-url-on-tab')
      end
      it "finds image on tab" do
        expect(subject.send(:variant_image_url, variant, product_page, tab)).to eq 'image-url-on-tab'
      end
    end

    context 'when image not found on variant, product or tab' do
      before do
        variant.stub(images_for: [])
        variant.stub_chain(:product, :images_for).and_return([])
        tab.stub(image: nil)
      end
      it "if found no where else, returns default image" do
        expect(subject.send(:variant_image_url, variant, product_page, tab)).to eq Spree::PolyvorFeedJob::DEFAULT_IMAGE_URL
      end
    end
  end
end