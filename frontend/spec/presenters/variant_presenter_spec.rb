require "spec_helper"

describe Spree::VariantPresenter do
  let(:product) { Spree::Product.new }
  let(:variant) { Spree::Variant.new(product: product) }
  let(:target) { Spree::Target.new }
  let(:currency) { "USD" }
  let(:device) { :desktop }
  let(:context) { { currency: currency, target: target, device: device } }
  subject { described_class.new(variant, view, context) }

  its(:id) { should eq variant.id }
  its(:name) { should eq variant.name }
  its(:product) { should eq product }
  its(:in_sale?) { should eq variant.in_sale? }
  its(:displayable_suppliers) { should eq variant.suppliers.displayable }

  describe "#level" do
    before { allow(product).to receive(:property).with("level").and_return "Level 1" }
    its(:level) { should eq "Level 1" }
  end

  ## Images

  its(:placeholder_image) { should eq("/assets/product-group/placeholder-470x600.gif") }

  describe "#first_image" do
    before { allow(subject).to receive(:images).and_return [true, false] }
    its(:first_image) { should eq true }
  end

  describe "#first_image_url" do
    it "returns the placeholder image when an image is not found" do
      expect(subject.first_image_url).to include "product-group/placeholder-470x600.gif"
    end

    context "when an image is found" do
      let(:image) { build(:image, viewable: variant) }

      before do
        allow(subject).to receive(:images).and_return [image]
      end

      it "returns the path to image with the requested style and uses `small` as a default style" do
        expect(subject.first_image_url(:product)).to include "/product/thinking-cat.jpg"
        expect(subject.first_image_url).to include "/small/thinking-cat.jpg"
      end
    end
  end

  describe "#images" do
    let(:mock_image) { double }
    context "when variants are available" do
      before { allow(variant).to receive(:images_for).with(target).and_return mock_image }

      it "returns targetted images from the variants" do
        expect(subject.send(:images)).to eq mock_image
      end
    end

    context "when there are no variant images" do
      before { allow(variant).to receive(:images_for).with(target).and_return [] }
      before { allow(product).to receive(:variant_images_for).with(target).and_return mock_image }

      it "returns master variant images without target" do
        expect(subject.send(:images)).to eq mock_image
      end
    end
  end

  context "#main_image_url" do
    let!(:image) { build_stubbed(:image, viewable: variant) }

    before do
      allow(subject).to receive(:images).and_return([image])
    end

    context "desktop" do
      it "returns an image tag for the main image" do
        expect(subject.main_image_url).to match "/spree/images/#{image.id}/product/thinking-cat.jpg"
      end
    end

    context "mobile" do
      let(:device) { :mobile }

      it "returns a mobile image url for the main image" do
        expect(subject.main_image_url).to match "/spree/images/#{image.id}/small/thinking-cat.jpg"
      end
    end
  end

  context "#main_image_options" do
    let(:image) { create(:image, viewable: variant) }
    it "returns an image options for the main image" do
      expected_options = {
        itemprop: "image",
        class: "zoomable",
        data: { zoomable: "/assets/product-group/placeholder-470x600.gif" }
      }
      expect(subject.main_image_options).to eq expected_options
    end

    context "mobile" do
      let(:context) { { currency: currency, target: target, device: :mobile } }

      it "returns an mobile image options for the main image" do
        expected_options = {
          itemprop: "image"
        }
        expect(subject.main_image_options).to eq expected_options
      end
    end
  end

  context "prices" do
    let(:variant) { Spree::Variant.new(product: product, prices: [price]) }
    let(:price)   { create(:price, amount: 8.99, sale_amount: 6.99, sale: false, is_kit: true, currency: currency) }
    its(:price)   { should eq price }
    its(:price_in_subunit) { should eq 899 }
    its(:price_html) { should eq "$8.99" }

    its(:sale_price) { should eq price }
    its(:sale_price_in_subunit) { should eq 699 }
    its(:sale_price_html) { should eq "$6.99" }
  end

  describe "#normal_price_classes" do
    let(:part) { build_stubbed(:base_product) }

    context "when variant is not in sale" do
      before { variant.in_sale = false }
      its(:normal_price_classes) { should eq "normal-price price" }
    end

    context "when variant is in sale" do
      before { variant.in_sale = true }
      its(:normal_price_classes) { should eq "normal-price price was" }
    end

    context "when product is not in sale and has an parts" do
      before do
        variant.in_sale = false
        allow(product).to receive(:parts).and_return [part]
      end

      its(:normal_price_classes) { should eq "normal-price price unselected" }
    end

    context "when product is in sale and has an parts" do
      before do
        variant.in_sale = true
        allow(product).to receive(:parts).and_return [part]
      end

      its(:normal_price_classes) { should eq "normal-price price was unselected" }
    end
  end

  describe "#sale_price_classes" do
    let(:part) { build_stubbed(:base_product) }

    context "when variant is not in sale" do
      before { variant.in_sale = false }
      its(:sale_price_classes) { should eq "sale-price price hide" }
    end

    context "when variant is in sale" do
      before { variant.in_sale = true }
      its(:sale_price_classes) { should eq "sale-price price" }
    end

    context "when product is not in sale and has an parts" do
      before do
        variant.in_sale = false
        allow(product).to receive(:parts).and_return [part]
      end

      its(:sale_price_classes) { should eq "sale-price price hide unselected" }
    end

    context "when product is in sale and has an parts" do
      before do
        variant.in_sale = true
        allow(product).to receive(:parts).and_return [part]
      end

      its(:sale_price_classes) { should eq "sale-price price unselected" }
    end
  end
end
