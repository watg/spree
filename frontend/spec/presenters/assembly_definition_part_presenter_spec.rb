require 'spec_helper'

describe Spree::AssemblyDefinitionPartPresenter do

  let(:assembly_definition_part) { Spree::AssemblyDefinitionPart.new(id: 21, optional: true, count: 2) }
  let(:variant) { Spree::Variant.new }
  let(:product) { Spree::Product.new(name: "Product Name") }

  let(:context) { { currency: 'USD'}}
  subject { described_class.new(assembly_definition_part, view, context) }

  # All directly delegated
  its(:optional?) { should eq true }
  its(:count) { should eq 2 }
  its(:id) { should eq 21 }
  its(:displayable_option_values) { should eq assembly_definition_part.displayable_option_values }
  its(:displayable_option_type) { should eq assembly_definition_part.displayable_option_type }
  its(:presentation) { should eq assembly_definition_part.presentation }

  context "#variants" do
    before { assembly_definition_part.variants << variant }

    its(:variants) { should eq [variant] }
    its(:first_variant) { should eq variant }
  end

  context "#product_name" do
    before { assembly_definition_part.product = product }

    its(:product_name) { should eq "Product Name" }
  end

  context "#product_options_presenter" do
    its(:product_options_presenter) { should be_kind_of(Spree::ProductOptionsPresenter) }

    it "should receive the correct arguments" do
      product_options_presenter = double
      expect(Spree::ProductOptionsPresenter).to receive(:new).with(assembly_definition_part, view, context).and_return(product_options_presenter)
      expect(subject.product_options_presenter).to eq product_options_presenter
    end
  end

end
