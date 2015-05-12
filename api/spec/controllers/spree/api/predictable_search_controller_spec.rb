require 'spec_helper'
describe Spree::Api::Search::PredictableSearchController, type: :controller do
  render_views

  before do
    stub_authentication!
  end

  describe ".search" do
    it "it calls PredictableSearch" do
      allow_any_instance_of(ActionView::Rendering).to receive(:view_context).and_return("stubbed_view")
      expect(::Api::Search::PredictableSearch).to receive(:new).
                                                    with("hat", "stubbed_view").and_call_original
      expect_any_instance_of(::Api::Search::PredictableSearch).to receive(:results)
      api_get :search, {keywords: "hat"}
    end
  end
end
