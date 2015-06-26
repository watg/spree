require 'spec_helper'

describe Spree::ProductPartPresenter do

  let(:product_part) { Spree::ProductPart.new(id: 21, optional: true, count: 2) }
  let(:variant) { Spree::Variant.new }
  let(:product) { Spree::Product.new(name: "Product Name") }

  let(:context) { { currency: 'USD'}}
  subject { described_class.new(product_part, view, context) }

  # All directly delegated
  its(:optional?) { should eq true }
  its(:count) { should eq 2 }
  its(:id) { should eq 21 }
  its(:displayable_option_values) { should eq product_part.displayable_option_values }
  its(:displayable_option_type) { should eq product_part.displayable_option_type }
  its(:presentation) { should eq product_part.presentation }

  context "#variants" do
    before do 
      product_part.variants << variant
    end

    its(:variants) { should eq [] }
    its(:first_variant) { should be_nil  }

    it "should call in_stock" do
      mocked_variants = double
      expect(mocked_variants).to receive(:in_stock)
      expect(product_part).to receive(:variants).and_return(mocked_variants)
      subject.variants
    end

  end

  context "#product_name" do
    before { product_part.part = product }

    its(:product_name) { should eq "Product Name" }
  end

  context "#variant_options" do

    it "instantiates a new VariantOption object" do
      expect(Spree::VariantOptions).to receive(:new).with(subject.variants, subject.currency, nil)
      subject.send(:variant_options)
    end

    before do 

    end

    it "instantiates a new VariantOption object" do
      expect(Spree::VariantOptions).to receive(:new).with(subject.variants, subject.currency, nil)
      subject.send(:variant_options)
    end

  end

  context "methods that delegate to variant_options" do

    let(:variant_options) { double('variant_options')}

    before do
      allow(subject).to receive(:variant_options).and_return(variant_options)
    end

    describe "#variant_tree" do

      it "delegates to variant_options" do
        expect(variant_options).to receive(:simple_tree)
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

end
