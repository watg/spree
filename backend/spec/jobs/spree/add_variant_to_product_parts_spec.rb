require 'spec_helper'

describe Spree::Jobs::AddVariantToProductParts do

  let(:product) { create(:base_product) }
  let(:assembly_definition_part) { create(:assembly_definition_part, product: product) }
  let(:part) { assembly_definition_part.part }

  let(:variant) { create(:base_variant) }

  context 'add_all_available_variants is true' do

    before do
      assembly_definition_part.add_all_available_variants = true
    end

    context 'variant is not associated to assembly definition part' do
      it 'does not add variant to assembly definition/product/variant' do
        Spree::Jobs::AddVariantToProductParts.new(variant).perform
        expect(assembly_definition_part.assembly_definition_variants).to be_empty
      end
    end

    context 'variant is associated to assembly definition product' do
      let(:new_variant) { create(:base_variant, product: part) }

      it 'adds variant to assembly definition part' do
        expect(assembly_definition_part.assembly_definition_variants).to be_empty
        Spree::Jobs::AddVariantToProductParts.new(new_variant).perform
        expect(assembly_definition_part.assembly_definition_variants.count).to eq(1)
      end
    end
  end

  context 'add_all_available_variants is false' do
    let(:another_variant) { create(:base_variant, product: part)}
    let(:non_updating_assembly_definition_part) do 
      create(:assembly_definition_part, product: product)
    end
    before do
      non_updating_assembly_definition_part.add_all_available_variants = false
    end

    it 'does not add variant to assembly definition part' do
      expect(non_updating_assembly_definition_part.add_all_available_variants).to be false
      expect(non_updating_assembly_definition_part.assembly_definition_variants).to be_empty
      Spree::Jobs::AddVariantToProductParts.new(another_variant).perform
      expect(non_updating_assembly_definition_part.assembly_definition_variants.count).to eq(0)
    end
  end

end
