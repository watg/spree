require "spec_helper"

describe Spree::Admin::AssemblyDefinitionPartsController do
  stub_authorization!

  let(:variant_assembly)   { create(:variant) }
  let(:product)            { variant_assembly.product }
  let!(:ass_def)           { create(:assembly_definition, variant: variant_assembly) }

  let(:variant_part)       { create(:base_variant) }
  let(:part)               { variant_part.product }

  let(:params) do
    { part_product_id:  part.id,
      part_type:  "product",
      part_count:   "1",
      assembly_definition_id:  ass_def.id
    }
  end

  let(:actual)             { Spree::AssemblyDefinitionPart.first }

  describe '#create' do
    it "creates an assembly definition part" do
      xhr :spree_post, :create, params
      expect(actual.part).to eq part
      expect(actual.product).to eq product
      expect(actual.product_id).to eq product.id
    end
  end
end
