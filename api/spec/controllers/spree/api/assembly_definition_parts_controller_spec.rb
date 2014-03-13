require 'spec_helper'

describe Spree::Api::AssemblyDefinitionPartsController do
  render_views
  let!(:ass_def_part) { Spree::AssemblyDefinitionPart.create(assembly_definition_id: 12, count: 3, product_id: 3, optional: true) }
  let!(:variants) { [create(:variant)] }
  let!(:attributes) { [:id, :options_text] }
  before do
    stub_authentication!
    expect_any_instance_of(Spree::AssemblyDefinitionPart).to receive(:variants).any_number_of_times.and_return(variants)
  end
  
  it "list available variants for an assembly definition part" do
    api_get :variants, {id: ass_def_part.id}
    expect(json_response["id"]).to eq(ass_def_part.id)
    expect(json_response["variants"][0]).to have_attributes(attributes)
  end
end
