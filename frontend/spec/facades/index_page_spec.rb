require "spec_helper"
require_relative "../modules/indexable_shared_examples"

describe IndexPage do
  let(:context) do
    {
      device: :tablet,
      currency: "USD"
    }
  end

  subject { described_class.new(context: context) }

  # TODO
  it_behaves_like Indexable


  # describe "#suites" do
  #   let(:taxon) { create(:taxon, :permalink => "test") }

  #   let(:suite_tabs_1) { [ create(:suite_tab) ] }
  #   let(:suite_tabs_2) { [ create(:suite_tab) ] }
  #   let(:suite_tabs_3) { [ create(:suite_tab) ] }

  #   let!(:suite_1) { create(:suite, tabs: suite_tabs_1) }
  #   let!(:suite_2) { create(:suite, tabs: suite_tabs_2) }
  #   let!(:suite_3) { create(:suite, tabs: suite_tabs_3) }

  #   let!(:suites) { [ suite_1, suite_2, suite_3] }

  #   before do
  #     suite_1.taxons << taxon
  #     suite_2.taxons << taxon
  #     suite_3.taxons << taxon
  #   end

  #   it "assigns @suites to the suites, which belong to a taxon" do
  #     spree_get :show, :id => taxon.permalink

  #     expect(assigns(:suites)).to eq suites
  #     expect(response).to render_template(:show)
  #   end

  #   it "only returns the number of suites required by per_page" do
  #     spree_get :show, :id => taxon.permalink, per_page: 1

  #     expect(assigns(:suites).size).to eq 1
  #     expect(response).to render_template(:show)
  #   end

  #   context "no suites on page" do

  #     it "loads the first page" do
  #       spree_get :show, :id => taxon.permalink, per_page: 10, page: 2

  #       expect(assigns(:suites).size).to eq 3
  #       expect(response).to render_template(:show)
  #     end

  #   end

  #   context "suite has no tabs" do

  #     let!(:suite_1) { create(:suite, tabs: suite_tabs_1) }
  #     let!(:suite_2) { create(:suite, tabs: []) }
  #     let!(:suite_3) { create(:suite, tabs: []) }

  #     it "does not return suites that have no tabs" do
  #       spree_get :show, :id => taxon.permalink, per_page: 3
  #       expect(assigns(:suites).size).to eq 1
  #       expect(response).to render_template(:show)
  #     end
  #   end
  # end
end
