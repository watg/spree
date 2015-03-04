require 'spec_helper'

describe Spree::AssemblyDefinitionPresenter do

  let(:assembly_definition) { Spree::AssemblyDefinition.new() }

  let(:target) { Spree::Target.new }

  let(:context) { { currency: 'USD'}}
  subject { described_class.new(assembly_definition, view, context.merge(target: target)) }

  context "#images" do
    let(:images) { double() }

    it "should call #images and pass a target" do
      expect(images).to receive(:with_target).with(target).and_return true
      expect(assembly_definition).to receive(:images).and_return(images)
      expect(subject.images).to eq true
    end
  end

  describe "#displayable_suppliers" do
    let(:product) { Spree::Product.new }
    let(:variant) { Spree::Variant.new }
    let(:assembly_definition) { Spree::AssemblyDefinition.new }
    let(:part1) { Spree::AssemblyDefinitionPart.new }
    let(:suppliers) { [Spree::Supplier.new] }

    it "returns empy list if there is not a part" do
        expect(subject.displayable_suppliers).to eq []
    end

    context 'when assembly definition is present' do
      before do
        mock_object = double('mock')
        allow(variant).to receive(:suppliers).and_return(mock_object)
        allow(mock_object).to receive(:displayable_with_nickname).and_return(suppliers)

        assembly_definition.parts << part1
        product.master.assembly_definition = assembly_definition
        part1.variants << variant
      end

      it "uses the main part supplier if available" do
        expect(subject.displayable_suppliers).to eq suppliers
      end

      context "when main part is set" do
        let(:variant_2) { Spree::Variant.new }
        let(:part2) { Spree::AssemblyDefinitionPart.new }
        let(:suppliers_2) { [Spree::Supplier.new] }

        before do
          mock_object = double('mock')
          allow(variant_2).to receive(:suppliers).and_return(mock_object)
          allow(mock_object).to receive(:displayable_with_nickname).and_return(suppliers_2)
          assembly_definition.parts << part2
          part2.variants << variant_2
        end

        it "uses the first variant from the first part when a main part is not present" do
          assembly_definition.main_part = part2
          expect(subject.displayable_suppliers).to eq suppliers_2
        end
      end

    end

  end

end
