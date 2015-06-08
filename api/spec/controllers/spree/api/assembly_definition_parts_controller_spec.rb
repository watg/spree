require 'spec_helper'

describe Spree::Api::AssemblyDefinitionPartsController do
  render_views

  let(:variant_assembly)    { create(:variant) }
  let(:assembly_definition) { create(:assembly_definition, variant: variant_assembly) }

  let(:variant_part)  { create(:base_variant) }
  let(:product_part)  { variant_part.product }

  let!(:ass_def_part) { Spree::AssemblyDefinitionPart.create(opts) }
  let(:opts)          { { assembly_definition: assembly_definition, part_product: product_part } }
  let!(:variants)     { [create(:variant)] }
  let!(:attributes)   { [:id, :options_text] }

  before do
    stub_authentication!
    expect_any_instance_of(Spree::AssemblyDefinitionPart).to receive(:variants).and_return(variants)
  end
  
  it "list available variants for an assembly definition part" do
    api_get :variants, {id: ass_def_part.id}
    expect(json_response["id"]).to eq(ass_def_part.id)
    expect(json_response["variants"][0]).to have_attributes(attributes)
  end
end
