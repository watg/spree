require 'spec_helper'

describe Spree::VariantPresenter do
  let(:product) { Spree::Product.new }
  let(:variant) { Spree::Variant.new(product: product) }
  let(:target) { Spree::Target.new }
  let(:currency) { 'USD' }
  let(:device) { :desktop }
  let(:context) { { currency: currency, target: target, device: device } }
  subject { described_class.new(variant, view, context) }


  its(:id) { should eq variant.id }
  its(:name) { should eq variant.name }
  its(:product) { should eq product }
  its(:in_sale?) { should eq variant.in_sale? }
  its(:displayable_suppliers) { should eq variant.suppliers.displayable }


  describe "#level" do
    before { allow(product).to receive(:property).with('level').and_return 'Level 1' }
    its(:level) { should eq 'Level 1' }
  end


  ## Images

  its(:placeholder_image) { should eq('/assets/product-group/placeholder-470x600.gif') }

  describe "#first_image" do
    before { allow(subject).to receive(:images).and_return [true, false] }
    its(:first_image) { should eq true }
  end

  describe '#first_image_url' do
    it "returns the placeholder image when an image is not found" do
      expect(subject.first_image_url).to include 'product-group/placeholder-470x600.gif'
    end

    context 'when an image is found' do
      let(:image) { build(:image, viewable: variant) }

      before do
        allow(subject).to receive(:images).and_return [image]
      end

      it "returns the path to image with the requested style and uses `small` as a default style" do
        expect(subject.first_image_url(:product)).to include '/product/thinking-cat.jpg'
        expect(subject.first_image_url).to include '/small/thinking-cat.jpg'
      end
    end
  end

  describe "#images" do
    context 'when variants are available' do
      before { allow(variant).to receive(:images_for).with(target).and_return true }

      it "returns targetted images from the variants" do
        expect(subject.send(:images)).to eq true
      end
    end

    context 'when only master variant is available' do
      before { allow(product).to receive(:memoized_images).and_return true }

      it 'returns master variant images without target' do
        expect(subject.send(:images)).to eq true
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
      let(:context) { { currency: currency, target: target, device: :mobile}}

      it "returns an mobile image options for the main image" do
        expected_options = {
          itemprop: "image"
        }
        expect(subject.main_image_options).to eq expected_options
      end
    end
  end



  ## Prices

  context 'prices' do
    let(:normal_price) { variant.price_normal_in(currency) }
    let(:sale_price) { variant.price_normal_sale_in(currency) }

    before do
      normal_price.amount = 8.99
      sale_price.amount = 6.99
    end

    its(:price) { should eq normal_price }
    its(:price_in_subunit) { should eq 899 }
    its(:price_html) { should eq '$8.99' }

    its(:sale_price) { should eq sale_price }
    its(:sale_price_in_subunit) { should eq 699 }
    its(:sale_price_html) { should eq '$6.99' }
  end

  describe '#normal_price_classes' do
    context 'when variant is not in sale' do
      before { variant.in_sale = false }
      its(:normal_price_classes) { should eq 'normal-price price' }
    end

    context 'when variant is in sale' do
      before { variant.in_sale = true }
      its(:normal_price_classes) { should eq 'normal-price price was' }
    end

    context 'when product is not in sale and has an assembly_definition' do
      before do
        variant.in_sale = false
        allow(product).to receive(:assembly_definition).and_return true
      end

      its(:normal_price_classes) { should eq 'normal-price price unselected' }
    end

    context 'when product is in sale and has an assembly_definition' do
      before do
        variant.in_sale = true
        allow(product).to receive(:assembly_definition).and_return true
      end

      its(:normal_price_classes) { should eq 'normal-price price was unselected' }
    end
  end

  describe '#sale_price_classes' do
    context 'when variant is not in sale' do
      before { variant.in_sale = false }
      its(:sale_price_classes) { should eq 'sale-price price hide' }
    end

    context 'when variant is in sale' do
      before { variant.in_sale = true }
      its(:sale_price_classes) { should eq 'sale-price price' }
    end

    context 'when product is not in sale and has an assembly_definition' do
      before do
        variant.in_sale = false
        allow(product).to receive(:assembly_definition).and_return true
      end

      its(:sale_price_classes) { should eq 'sale-price price hide unselected' }
    end

    context 'when product is in sale and has an assembly_definition' do
      before do
        variant.in_sale = true
        allow(product).to receive(:assembly_definition).and_return true
      end

      its(:sale_price_classes) { should eq 'sale-price price unselected' }
    end
  end

end
