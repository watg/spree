require 'spec_helper'

describe Spree::Api::AssemblyDefinitionsController do
  render_views
  let(:variants) { [create(:variant)] }
  let!(:ass_def) { double(id: 3, selected_variants_out_of_stock: {"1" => [], "3" => [2342, 323]}) }

  before do
    stub_authentication!
    allow(Spree::AssemblyDefinition).to receive(:find).and_return(ass_def)
  end
  
  it "returns a data structures of variants out of stock per assembly definition part" do
    api_get :out_of_stock_variants, {id: ass_def.id}
    expect(json_response["id"]).to eq(ass_def.id)
    expect(json_response["parts"]).to eq(ass_def.selected_variants_out_of_stock)
  end
end
