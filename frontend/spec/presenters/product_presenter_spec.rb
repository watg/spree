require "spec_helper"

describe Spree::ProductPresenter do
  let(:product) { Spree::Product.new }
  let(:target) { Spree::Target.new }
  let(:template) { { current_country_code: "US" } }
  let(:device) { :desktop }
  let(:context) { { currency: "USD", target: target, device: device } }
  let(:variant) { Spree::Variant.new }

  subject { described_class.new(product, target, context) }

  describe "#id" do
    it { expect(subject.id).to eq product.id }
  end

  describe "#name" do
    it { expect(subject.name).to eq product.name }
  end

  describe "#slug" do
    it { expect(subject.slug).to eq product.slug }
  end

  describe "#out_of_stock_override?" do
    it { expect(subject.out_of_stock_override?).to eq product.out_of_stock_override? }
  end

  describe "#master" do
    it { expect(subject.master).to eq product.master }
  end

  describe "#price" do
    it { expect(subject.price).to eq product.price_normal_in("USD") }
  end

  describe "#personalisations" do
    it { expect(subject.personalisations).to eq product.personalisations }
  end

  describe "#personalisation_images" do
    it { expect(subject.personalisation_images).to eq product.personalisation_images }
  end

  describe "#optional_parts_for_display" do
    it { expect(subject.optional_parts_for_display).to eq product.optional_parts_for_display }
  end

  it "#variants should return only targetted variants that are in_stock" do
    mocked_variants = double
    expect(mocked_variants).to receive(:in_stock)
    expect(product).to receive(:variants_for).with(target).and_return(mocked_variants)
    subject.variants
  end

  it "#clean_description should accept target as an argument" do
    expect(product).to receive(:clean_description_for).with(target)
    subject.clean_description
  end

  it "#images should accept target as an argument" do
    expect(product).to receive(:images_for).with(target)
    subject.images
  end

  it "#variant_images should accept target as an argument" do
    expect(product).to receive(:variant_images_for).with(target)
    subject.variant_images
  end

  describe "#complex_carousel?" do
    context "when variant has option values and images" do
      let(:variant_options) { double("variant_options") }

      before do
        allow(subject).to receive(:variant_option_values).and_return(variant_options)
        allow(subject).to receive(:variant_images).and_return(["image"])
      end

      describe "#complex_carousel?" do
        it { expect(subject.complex_carousel?).to eq true }
      end
    end

    context "when variant has no option values or image" do
      describe "#complex_carousel?" do
        it { expect(subject.complex_carousel?).to eq false }
      end
    end
  end

  describe "#parts?" do
    let(:product_part) { build_stubbed(:product_part) }
    it "returns the true if there are product_parts" do
      allow(product).to receive(:product_parts).and_return([product_part])
      expect(subject.parts?).to eq true
    end

    context "with assembly definition" do
      let(:assembly_definition) { Spree::AssemblyDefinition.new }
      let(:assembly_definition_part) { Spree::AssemblyDefinitionPart.new }

      it "returns the false if there are no product_parts" do
        allow(product).to receive(:product_parts).and_return([])
        expect(subject.parts?).to eq false
      end
    end
  end

  describe "#kit?" do
    before { product.product_type = product_type }

    context "kit" do
      let(:product_type) { build_stubbed(:product_type_kit, :kit) }
      it { expect(subject.kit?).to be_truthy }
    end

    context "not a kit" do
      let(:product_type) { build_stubbed(:product_type) }
      it { expect(subject.kit?).to be_falsey }
    end
  end

  describe "#ready_to_wear_with_parts?" do
    let(:type)  { build_stubbed(:product_type) }
    before      { product.product_type = type }

    context "ready to wear with parts" do
      let(:part) { build_stubbed(:product) }
      before     { product.parts = [part] }
      it         { expect(subject.ready_to_wear_with_parts?).to be_truthy }
    end

    context "ready to wear" do
      it { expect(subject.ready_to_wear_with_parts?).to be_falsey }
    end
  end

  describe "#product_parts" do
    it "returns the product_parts" do
      expect(product).to receive(:product_parts)
      subject.product_parts
    end
  end

  describe "#video" do
    let(:product) { create(:product) }

    context "product has video" do
      before { product.videos.create(embed: "youtube embed") }
      it     { expect(subject.video).to eq product.videos.first.embed }
    end

    context "product does not have video" do
      it { expect(subject.video).to be_falsey }
    end
  end

  context "#product_parts_images" do
    let(:product_parts_images) { double }

    it "calls #images and pass a target" do
      expect(product_parts_images).to receive(:with_target).with(target).and_return true
      expect(product).to receive(:product_parts_images).and_return(product_parts_images)
      expect(subject.product_parts_images).to eq true
    end
  end

  describe "#delivery_partial" do
    let(:product) { create(:product) }
    let(:template) { { current_country_code: "US" } }
    subject { described_class.new(product, template, context) }

    context "product is a pattern" do
      let(:product) { create(:product, :pattern) }
      it { expect(subject.delivery_partial).to eq %(delivery_pattern) }
    end

    context "product is not a pattern" do
      context "customer is browsing from America" do
        it "returns US specific partial" do
          allow(template).to receive(:current_country_code).and_return("US")
          expect(subject.delivery_partial).to eq %(delivery_us)
        end
      end

      context "customer is not browsing from key country" do
        it "returns default partial" do
          allow(template).to receive(:current_country_code).and_return("RU")
          expect(subject.delivery_partial).to eq %(delivery_default)
        end
      end
    end
  end

  describe "#part_price_in_pence" do
    let(:variant) { Spree::Variant.new(prices: [price]) }
    let(:price)   { create(:price, sale: false, is_kit: true, amount: 9.99, part_amount: 5.99) }

    context "when variant is master" do
      before { variant.is_master = true }
      it     { expect(subject.part_price_in_pence(variant)).to eq 999 }
    end

    context "when variant is master" do
      before { variant.is_master = false }
      it     { expect(subject.part_price_in_pence(variant)).to eq 599 }
    end
  end

  describe "#part_quantity" do
    it "returns count_part value when available" do
      expect(subject.part_quantity(double(count_part: 2))).to eq 2
    end

    it "returns 1 when count_part is not available" do
      expect(subject.part_quantity(double)).to eq 1
    end
  end

  ## Presenters

  describe "#sale_variant_or_first_variant_or_master" do
    it "returns an the first variant in stock when variants are available" do
      sale_variant = build(:variant, in_sale: true)
      allow(subject).to receive(:variants).and_return [variant, sale_variant]
      expect(subject.sale_variant_or_first_variant_or_master).to eq(sale_variant)
    end

    it "returns an the first variant in stock when variants are available" do
      allow(subject).to receive_message_chain(:variants).and_return [variant]
      expect(subject.sale_variant_or_first_variant_or_master).to eq(variant)
    end

    it "returns master variant when no variants are available" do
      allow(product).to receive(:master).and_return variant
      expect(subject.sale_variant_or_first_variant_or_master).to eq(variant)
    end
  end

  describe "#image_style" do
    context "desktop" do
      it "returns an image image style for the main image" do
        expect(subject.image_style).to eq :product
      end
    end

    context "mobile" do
      let!(:device) { :mobile }

      it "returns a mobile image style for the main image" do
        expect(subject.image_style).to eq :small
      end
    end
  end

  context "#variant_options" do
    it "instantiates a new VariantOption object" do
      expect(Spree::VariantOptions).to receive(:new).with(subject.variants, subject.currency)
      subject.send(:variant_options)
    end
  end

  context "methods that delegate to variant_options" do
    let(:variant_options) { double("variant_options") }

    before do
      allow(subject).to receive(:variant_options).and_return(variant_options)
    end

    describe "#option_types_and_values" do
      it "delegates to variant_options" do
        expect(variant_options).to receive(:option_types_and_values_for).with(subject.sale_variant_or_first_variant_or_master)
        subject.option_types_and_values
      end
    end

    describe "#variant_tree" do
      it "delegates to variant_options" do
        expect(variant_options).to receive(:tree)
        subject.variant_tree
      end
    end

    describe "#option_type_order" do
      it "delegates to variant_options" do
        expect(variant_options).to receive(:option_type_order)
        subject.option_type_order
      end
    end

    describe "#variant_option_values" do
      it "delegates to variant_options" do
        expect(variant_options).to receive(:variant_option_values)
        subject.variant_option_values
      end
    end

    describe "#grouped_option_values_in_stock" do
      it "delegates to variant_options" do
        expect(variant_options).to receive(:grouped_option_values_in_stock)
        subject.grouped_option_values_in_stock
      end
    end
  end
end
