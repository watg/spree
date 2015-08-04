require "spec_helper"

describe Spree::ProductPartPresenter do
  let(:product_part) { Spree::ProductPart.new(id: 21, optional: true, count: 2) }
  let(:variant) { Spree::Variant.new }
  let(:product) { Spree::Product.new(name: "Product Name") }

  let(:context) { { currency: "USD" } }
  subject { described_class.new(product_part, view, context) }

  # All directly delegated

  describe "#optional?" do
    subject { super().optional? }
    it { is_expected.to eq true }
  end

  describe "#count" do
    subject { super().count }
    it { is_expected.to eq 2 }
  end

  describe "#id" do
    subject { super().id }
    it { is_expected.to eq 21 }
  end

  describe "#displayable_option_values" do
    subject { super().displayable_option_values }
    it { is_expected.to eq product_part.displayable_option_values }
  end

  describe "#displayable_option_type" do
    subject { super().displayable_option_type }
    it { is_expected.to eq product_part.displayable_option_type }
  end

  describe "#presentation" do
    subject { super().presentation }
    it { is_expected.to eq product_part.presentation }
  end

  describe "#part_template" do
    context "mobile" do
      let(:context) { { device: :mobile } }
      let(:partial) { "spree/suites/mobile/optional_part" }
      it { expect(subject.template).to eq partial }
    end

    context "desktop" do
      let(:context) { { device: :desktop } }
      let(:partial) { "optional_part" }
      it { expect(subject.template).to eq partial }
    end
  end

  context "#variants" do
    before do
      product_part.variants << variant
    end

    describe "#variants" do
      subject { super().variants }
      it { is_expected.to eq [] }
    end

    describe "#first_variant" do
      subject { super().first_variant }
      it { is_expected.to be_nil  }
    end

    it "calls in_stock" do
      mocked_variants = double
      expect(mocked_variants).to receive(:in_stock)
      expect(product_part).to receive(:variants).and_return(mocked_variants)
      subject.variants
    end
  end

  context "#product_name" do
    before { product_part.part = product }

    describe "#product_name" do
      subject { super().product_name }
      it { is_expected.to eq "Product Name" }
    end
  end

  context "#variant_options" do
    it "instantiates a new VariantOption object" do
      expect(Spree::VariantOptions).to receive(:new).with(subject.variants, subject.currency, nil)
      subject.send(:variant_options)
    end
  end

  context "methods that delegate to variant_options" do
    let(:variant_options) { double("variant_options") }

    before do
      allow(subject).to receive(:variant_options).and_return(variant_options)
    end

    describe "#variant_tree" do
      it "delegates to variant_options" do
        expect(variant_options).to receive(:option_value_simple_tree)
        subject.variant_tree
      end
    end

    describe "#displayable_option_values" do
      it "delegates to variant_options" do
        expect(variant_options).to receive(:option_values_in_stock)
        subject.displayable_option_values
      end
    end
  end

  describe "#variant_option_objects" do
    context "when variants and option values present" do
      let!(:option_value) { create(:option_value) }
      let!(:option_type) { create(:option_type, option_values: [option_value]) }
      let!(:image) { create(:image) }

      it "returns a hash of objects using the values" do
        variant = mock_model(Spree::Variant)
        allow(variant).to receive(:option_values).and_return([option_value])
        allow(variant).to receive(:part_image).and_return(image)
        allow(subject).to receive(:variants).and_return([variant])
        allow(subject).to receive(:displayable_option_type).and_return(option_type)

        array = subject.variant_option_objects
        struct = array.first

        expect(struct).to be_a(::VariantPartOptions)
        expect(struct.variant_id).to eq(variant.id)
        expect(struct.presentation).to eq(option_value.presentation)
        expect(struct.type).to eq(option_type.name)
        expect(struct.name).to eq(option_value.name)
        expect(struct.image).to eq(variant.part_image.attachment)
        expect(struct.value).to eq(option_value.url_safe_name)
        expect(struct.classes).to be_kind_of String
        expect(struct.classes).to include(option_value.url_safe_name)
        expect(struct.classes).to include("option-value")
        expect(struct.classes).to include(option_type.name)
      end

      context "when no part_image present on variant" do
        context "option value image is present" do
          let(:option_image) { "image" }
          it "returns the option value image" do
            variant = mock_model(Spree::Variant)

            allow(variant).to receive(:part_image).and_return(nil)
            allow(subject).to receive(:variants).and_return([variant])
            allow(subject).to receive(:displayable_option_type).and_return(option_type)
            # set up option image
            allow(variant).to receive(:option_values).and_return([option_value])
            allow(option_value).to receive(:image).and_return(option_image)
            allow(option_image).to receive(:url).and_return("coolimage.png")

            array = subject.variant_option_objects
            struct = array.first
            expect(struct.image).to eq(option_value.image)
          end
        end

        context "option value image is missing" do
          it "returns nil" do
            variant = mock_model(Spree::Variant)

            allow(variant).to receive(:option_values).and_return([option_value])
            allow(variant).to receive(:part_image).and_return(nil)
            allow(subject).to receive(:variants).and_return([variant])
            allow(subject).to receive(:displayable_option_type).and_return(option_type)

            array = subject.variant_option_objects
            struct = array.first
            expect(struct.image).to eq(nil)
          end
        end
      end
    end

    context "when no variant present" do
      it "returns an empty array" do
        expect(subject.variant_option_objects).to eq([])
      end
    end
  end
end
