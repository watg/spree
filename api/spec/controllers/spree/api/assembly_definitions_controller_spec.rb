require 'spec_helper'

describe Spree::Api::AssemblyDefinitionsController do
  render_views
  let!(:ass_def) { Spree::AssemblyDefinition.create(assembly_id: 12, count: 3, part_id: 3, optional: true) }
  let!(:variants) { [create(:variant)] }
  let!(:attributes) { [:id, :options_text] }
  before do
    stub_authentication!
    expect_any_instance_of(Spree::AssemblyDefinition).to receive(:variants).any_number_of_times.and_return(variants)
  end
  
  it "list available variants for an assembly definition part" do
    api_get :parts, {id: ass_def.id}
    expect(json_response["id"]).to eq(ass_def.id)
    expect(json_response["variants"][0]).to have_attributes(attributes)
  end
end
