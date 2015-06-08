require 'spec_helper'

describe Spree::Jobs::AddVariantToAssemblyPart do

  let(:assembly_definition) { create(:assembly_definition, variant: create(:base_variant) ) }
  let(:assembly_definition_part) { create(:assembly_definition_part, assembly_definition: assembly_definition)}
  let(:part_product) { assembly_definition_part.part_product }

  let(:variant) { create(:base_variant) }

  context 'add_all_available_variants is true' do

    before do
      assembly_definition_part.add_all_available_variants = true
    end

    context 'variant is not associated to assembly definition part' do
      it 'does not add variant to assembly definition/product/variant' do
        Spree::Jobs::AddVariantToAssemblyPart.new(variant).perform
        expect(assembly_definition_part.assembly_definition_variants).to be_empty
      end
    end

    context 'variant is associated to assembly definition product' do
      let(:new_variant) { create(:base_variant, product: part_product)}

      it 'adds variant to assembly definition part' do
        expect(assembly_definition_part.assembly_definition_variants).to be_empty
        Spree::Jobs::AddVariantToAssemblyPart.new(new_variant).perform
        expect(assembly_definition_part.assembly_definition_variants.count).to eq(1)
      end
    end
  end

  context 'add_all_available_variants is false' do
    let(:another_variant) { create(:base_variant, product: part_product)}
    let(:non_updating_assembly_definition_part) { create(:assembly_definition_part, assembly_definition: assembly_definition)}

    before do
      non_updating_assembly_definition_part.add_all_available_variants = false
    end

    it 'does not add variant to assembly definition part' do
      expect(non_updating_assembly_definition_part.add_all_available_variants).to be false
      expect(non_updating_assembly_definition_part.assembly_definition_variants).to be_empty
      Spree::Jobs::AddVariantToAssemblyPart.new(another_variant).perform
      expect(non_updating_assembly_definition_part.assembly_definition_variants.count).to eq(0)
    end
  end

end
