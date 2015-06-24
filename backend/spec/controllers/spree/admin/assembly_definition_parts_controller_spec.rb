require 'spec_helper'

describe Spree::Admin::AssemblyDefinitionPartsController do
  stub_authorization!

  let(:variant_assembly)   { create(:variant) }
  let(:product)            { variant_assembly.product }
  let!(:ass_def)           { create(:assembly_definition, variant: variant_assembly) }

  let(:variant_part)       { create(:base_variant) }
  let(:product_part)       { variant_part.product }

  let(:params) do
    { part_product_id:  product_part.id,
      part_type:  "product",
      part_count:   "1",
      assembly_definition_id:  ass_def.id
    }
  end

  it "list available variants for an assembly definition part" do
    xhr :spree_post, :create, params
    expect(Spree::AssemblyDefinitionPart.first.part).to eq product_part
  end
end
