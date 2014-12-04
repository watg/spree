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

  it "#grouped_option_values should accept target as an argument" do
    expect(product).to receive(:grouped_option_values_for).with(target)
    subject.grouped_option_values
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

  describe "#product_options_presenter" do
    it "wraps the product options in their own presenter" do
      presenter = subject.product_options_presenter
      expect(presenter).to be_kind_of Spree::ProductOptionsPresenter
      expect(presenter.item).to eq product
    end
  end

  describe "#assembly_definition_presenter" do
    it "returns an asembly definition presenter when an assembly definition is available" do
      allow(subject).to receive(:assembly_definition).and_return true
      expect(subject.assembly_definition_presenter).to be_kind_of Spree::AssemblyDefinitionPresenter
      expect(subject.assembly_definition_presenter.assembly_definition).to eq true
    end

    it "returns nil when an assembly definition is not available" do
      expect(subject.assembly_definition_presenter).to be_nil
    end
  end

  describe "#assembly_definition_part_presenters" do
    let(:part) { Spree::AssemblyDefinitionPart.new }

    before do
      allow(subject).to receive(:assembly_definition_parts).and_return [part]
    end

    it "wraps each assembly definition part in a presenter" do
      presenters = subject.assembly_definition_part_presenters
      expect(presenters).to be_kind_of Array
      expect(presenters.first).to be_kind_of Spree::AssemblyDefinitionPartPresenter
      expect(presenters.first.assembly_definition_part).to eq part
    end
  end

  describe "#suppliers_variant_presenter returns a variant presenter" do
    let(:assembly_definition) { Spree::AssemblyDefinition.new }
    let(:part1) { Spree::AssemblyDefinitionPart.new }
    let(:part2) { Spree::AssemblyDefinitionPart.new }

    context 'when assembly definition is present' do
      before do
        assembly_definition.parts << part1
        assembly_definition.parts << part2
        product.master.assembly_definition = assembly_definition
      end

      it "uses the first variant from the first part when a main part is not present" do
        part1.variants << variant
        # assembly_definition.main_part = part2
        presenter = subject.suppliers_variant_presenter

        expect(presenter).to be_kind_of Spree::VariantPresenter
        expect(presenter.variant).to eq variant
      end

      it "uses the first variant from the first part when a main part is not present" do
        part2.variants << variant
        assembly_definition.main_part = part2
        presenter = subject.suppliers_variant_presenter

        expect(presenter).to be_kind_of Spree::VariantPresenter
        expect(presenter.variant).to eq variant
      end
    end

    context 'when an assembly_definition is not present' do
      it "uses first_variant_or_master" do
        presenter = subject.suppliers_variant_presenter

        expect(presenter).to be_kind_of Spree::VariantPresenter
        expect(presenter.variant).to be_kind_of Spree::Variant
      end
    end
  end

  describe "#first_variant_or_master_presenter" do
    it "returns an the first variant in stock when variants are available" do
      product.stub_chain(:variants, :in_stock, :first).and_return variant
      expect(subject.first_variant_or_master_presenter).to be_kind_of Spree::VariantPresenter
      expect(subject.first_variant_or_master_presenter.variant).to eq variant
    end

    it "returns master variant when no variants are available" do
      allow(product).to receive(:master).and_return variant
      expect(subject.first_variant_or_master_presenter).to be_kind_of Spree::VariantPresenter
      expect(subject.first_variant_or_master_presenter.variant).to eq variant
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


end
