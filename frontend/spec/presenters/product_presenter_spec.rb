require 'spec_helper'

describe Spree::ProductPresenter do

  let(:product) { Spree::Product.new }
  let(:target) { Spree::Target.new }
  let(:device) { :desktop }
  let(:context) { { currency: 'USD', target: target, device: device }}
  let(:variant) { Spree::Variant.new }

  subject { described_class.new(product, view, context) }


  its(:id) { should eq product.id }
  its(:name) { should eq product.name }
  its(:slug) { should eq product.slug }
  its(:out_of_stock_override?) { should eq product.out_of_stock_override? }

  its(:master) { should eq product.master }
  its(:price) { should eq product.price_normal_in("USD") }
  its(:personalisations) { should eq product.personalisations }
  its(:personalisation_images) { should eq product.personalisation_images }
  its(:optional_parts_for_display) { should eq product.optional_parts_for_display }


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

  context 'with assembly definition' do
    let(:assembly_definition) { Spree::AssemblyDefinition.new }
    let(:assembly_definition_part) { Spree::AssemblyDefinitionPart.new }

    before do
      assembly_definition.parts << assembly_definition_part
      product.master.assembly_definition = assembly_definition
    end

    its(:assembly_definition) { should eq assembly_definition }
    its(:assembly_definition?) { should eq true }
    its(:assembly_definition_parts) { should eq [assembly_definition_part] }
  end

  describe '#video' do
    let(:product) { create(:product) }

    context 'product has video' do
      before { product.videos.create(embed: "youtube embed") }
      it     { expect(subject.video).to eq product.videos.first.embed }
    end

    context 'product does not have video' do
      it { expect(subject.video).to be_falsey }
    end
  end

  describe '#delivery_partial' do
    context 'product is a pattern' do
      let(:product) { create(:product, :pattern) }
      it { expect(subject.delivery_partial).to eq %[delivery_pattern] }
    end

    context 'product is not a pattern' do
      let(:product) { create(:product) }
      it { expect(subject.delivery_partial).to eq %[delivery_default] }
    end
  end

  describe "#part_price_in_pence" do
    let(:variant) { Spree::Variant.new(prices: [price]) }
    let(:price)   { create(:price, sale: false, is_kit: true, amount: 9.99, part_amount: 5.99) }

    context 'when variant is master' do
      before { variant.is_master = true }
      it     { expect(subject.part_price_in_pence(variant)).to eq 999 }
    end

    context 'when variant is master' do
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
      subject.stub_chain(:variants).and_return [variant]
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

    let(:variant_options) { double('variant_options')}

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
