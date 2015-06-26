require 'spec_helper'

describe Spree::Jobs::AddVariantToProductParts do

  let(:product) { create(:base_product) }
  let(:product_part) { create(:product_part, product: product) }
  let(:part) { product_part.part }

  let(:variant) { create(:base_variant) }

  context 'add_all_available_variants is true' do

    before do
      product_part.add_all_available_variants = true
    end

    context 'variant is not associated to product_part' do
      it 'does not add variant to assembly definition/product/variant' do
        Spree::Jobs::AddVariantToProductParts.new(variant).perform
        expect(product_part.product_part_variants).to be_empty
      end
    end

    context 'variant is associated to assembly definition product' do
      let(:new_variant) { create(:base_variant, product: part) }

      it 'adds variant to assembly definition part' do
        expect(product_part.product_part_variants).to be_empty
        Spree::Jobs::AddVariantToProductParts.new(new_variant).perform
        expect(product_part.product_part_variants.count).to eq(1)
      end
    end
  end

  context 'add_all_available_variants is false' do
    let(:another_variant) { create(:base_variant, product: part)}
    let(:non_updating_product_part) { create(:product_part, product: product) }

    before do
      non_updating_product_part.add_all_available_variants = false
    end

    it 'does not add variant to assembly definition part' do
      expect(non_updating_product_part.add_all_available_variants).to be false
      expect(non_updating_product_part.product_part_variants).to be_empty
      Spree::Jobs::AddVariantToProductParts.new(another_variant).perform
      expect(non_updating_product_part.product_part_variants.count).to eq(0)
    end
  end

end
