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



  it "#variants should return only targetted variants" do
    expect(product).to receive(:variants_for).with(target)
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
    its(:assembly_definition_parts) { should eq [assembly_definition_part] }
  end

  describe "#part_price_in_pence" do
    before do
      price1 = variant.price_normal_in("USD").amount = 9.99
      price1 = variant.price_part_in("USD").amount = 5.99
    end

    context 'when variant is master' do
      before { variant.is_master = true }

      it "returns the part price of the variant in the context currency" do
        expect(subject.part_price_in_pence(variant)).to eq 999
      end
    end

    context 'when variant is master' do
      before { variant.is_master = false }

      it "returns the part price of the variant in the context currency" do
        expect(subject.part_price_in_pence(variant)).to eq 599
      end
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


  describe "#first_variant_or_master" do
    it "returns an the first variant in stock when variants are available" do
      product.stub_chain(:variants, :in_stock, :first).and_return variant
      expect(subject.first_variant_or_master).to be_kind_of Spree::Variant
      expect(subject.first_variant_or_master).to eq variant
    end

    it "returns master variant when no variants are available" do
      allow(product).to receive(:master).and_return variant
      expect(subject.first_variant_or_master).to be_kind_of Spree::Variant
      expect(subject.first_variant_or_master).to eq variant
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
        expect(variant_options).to receive(:option_types_and_values_for).with(subject.first_variant_or_master)
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

    describe "#option_values_in_stock" do

      it "delegates to variant_options" do
        expect(variant_options).to receive(:option_values_in_stock)
        subject.option_values_in_stock
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
