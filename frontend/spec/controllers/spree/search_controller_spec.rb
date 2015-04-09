require "spec_helper"

module Spree
  describe SearchController, type: :controller do
    describe "#show" do
      let(:searcher) { double(Search::Base) }
      let(:search_page) { double(SearchPageFacade) }

      it "should render a search page" do
        expect(Search::Base).to receive(:new)
          .with(keywords: "search word", page: 10, per_page: 2).and_return(searcher)

        expect(SearchPageFacade).to receive(:new)
          .with(context: kind_of(Hash), searcher: searcher, context: kind_of(Hash))
          .and_return(search_page)

        spree_get :show, keywords: "search word", page: 10, per_page: 2

        expect(assigns[:page]).to eq(search_page)
      end
    end
  end
end
