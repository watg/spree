require 'spec_helper'

module Spree
  describe TaxonsController do
    let(:taxon_show_service) { double(Spree::TaxonShowService) }
    let(:taxon) { double(Spree::Taxon, permalink: "taxon-permalink") }

    context "when taxon is found" do
      before do
        expect(Spree::TaxonShowService).to receive(:run!)
          .with(permalink: taxon.permalink).and_return(taxon)
      end

      describe "@page" do
        let(:index_page) { double(IndexPageFacade) }

        it "should render a search page" do

          expect(::IndexPageFacade).to receive(:new).with(
            taxon: taxon,
            context: kind_of(Hash),
            page: 10,
            per_page: 2
          ).and_return(index_page)

          spree_get :show, id: "taxon-permalink", page: 10, per_page: 2

          expect(assigns[:page]).to eq index_page
        end
      end

      describe "@context" do
        it "assigns @context to contain values from the context Application Controller" do
          spree_get :show, :id => taxon.permalink
          expected = {:currency=>"USD", :device => :desktop}
          expect(assigns(:context)).to eq expected
        end
      end
    end # end taxon is found

    context "when taxon is not found" do
      before do
        expect(Spree::TaxonShowService).to receive(:run!)
          .with(permalink: taxon.permalink).and_return(nil)
      end

      it "should return a not found page" do
        spree_get :show, id: "taxon-permalink"
        expect(response.status).to eq 404
      end
    end
  end
end
