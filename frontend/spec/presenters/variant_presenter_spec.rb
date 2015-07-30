require "spec_helper"

describe Spree::VariantPresenter do
  let(:product) { Spree::Product.new }
  let(:variant) { Spree::Variant.new(product: product) }
  let(:target) { Spree::Target.new }
  let(:currency) { "USD" }
  let(:device) { :desktop }
  let(:context) { { currency: currency, target: target, device: device } }
  subject { described_class.new(variant, view, context) }

  describe "#id" do
    it { expect(subject.id).to eq variant.id }
  end

  describe "#name" do
    it { expect(subject.name).to eq variant.name }
  end

  describe "#product" do
    it { expect(subject.product).to eq product }
  end

  describe "#in_sale?" do
    it { expect(subject.in_sale?).to eq variant.in_sale? }
  end

  describe "#displayable_suppliers" do
    it { expect(subject.displayable_suppliers).to eq variant.suppliers.displayable }
  end

  describe "#level" do
    before { allow(product).to receive(:property).with("level").and_return "Level 1" }

    describe "#level" do
      it { expect(subject.level).to eq "Level 1" }
    end
  end

  ## Images

  describe "#placeholder_image" do
    it { expect(subject.placeholder_image).to eq("/assets/product-group/placeholder-470x600.gif") }
  end

  describe "#first_image" do
    before { allow(subject).to receive(:images).and_return [true, false] }

    describe "#first_image" do
      it { expect(subject.first_image).to eq true }
    end
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

    describe "#price" do
      it { expect(subject.price).to eq price }
    end

    describe "#price_in_subunit" do
      it { expect(subject.price_in_subunit).to eq 899 }
    end

    describe "#price_html" do
      it { expect(subject.price_html).to eq "$8.99" }
    end

    describe "#sale_price" do
      it { expect(subject.sale_price).to eq price }
    end

    describe "#sale_price_in_subunit" do
      it { expect(subject.sale_price_in_subunit).to eq 699 }
    end

    describe "#sale_price_html" do
      it { expect(subject.sale_price_html).to eq "$6.99" }
    end
  end

  describe "#normal_price_classes" do
    let(:part) { build_stubbed(:base_product) }

    context "when variant is not in sale" do
      before { variant.in_sale = false }

      describe "#normal_price_classes" do
        it { expect(subject.normal_price_classes).to eq "normal-price price" }
      end
    end

    context "when variant is in sale" do
      before { variant.in_sale = true }

      describe "#normal_price_classes" do
        it { expect(subject.normal_price_classes).to eq "normal-price price was" }
      end
    end

    context "when product is not in sale and has an parts" do
      before do
        variant.in_sale = false
        allow(product).to receive(:parts).and_return [part]
      end

      describe "#normal_price_classes" do
        it { expect(subject.normal_price_classes).to eq "normal-price price unselected" }
      end
    end

    context "when product is in sale and has an parts" do
      before do
        variant.in_sale = true
        allow(product).to receive(:parts).and_return [part]
      end

      describe "#normal_price_classes" do
        it { expect(subject.normal_price_classes).to eq "normal-price price was unselected" }
      end
    end
  end

  describe "#sale_price_classes" do
    let(:part) { build_stubbed(:base_product) }

    context "when variant is not in sale" do
      before { variant.in_sale = false }

      describe "#sale_price_classes" do
        it { expect(subject.sale_price_classes).to eq "sale-price price hide" }
      end
    end

    context "when variant is in sale" do
      before { variant.in_sale = true }

      describe "#sale_price_classes" do
        it { expect(subject.sale_price_classes).to eq "sale-price price" }
      end
    end

    context "when product is not in sale and has an parts" do
      before do
        variant.in_sale = false
        allow(product).to receive(:parts).and_return [part]
      end

      describe "#sale_price_classes" do
        it { expect(subject.sale_price_classes).to eq "sale-price price hide unselected" }
      end
    end

    context "when product is in sale and has an parts" do
      before do
        variant.in_sale = true
        allow(product).to receive(:parts).and_return [part]
      end

      describe "#sale_price_classes" do
        it { expect(subject.sale_price_classes).to eq "sale-price price unselected" }
      end
    end
  end
end
