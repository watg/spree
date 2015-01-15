require 'spec_helper'

describe Spree::IndexPagesController, type: :controller do

  describe '#redirect_to_taxon_pages' do

    context "when a matching taxon page is found" do
      let!(:taxon) { create(:taxon, permalink: 'collections/whats-new') }

      it "redirects to the found taxon page with a permanent redirect code" do
        spree_get :show, :id => 'collections/whats-new'

        expect(response).to redirect_to spree.nested_taxons_path('collections/whats-new')
        expect(response.status).to eq 301 #:moved_permanently
      end
    end

    context 'when a TAXON_ALIAS exists for the given index page permalink' do
      let!(:taxon) { create(:taxon, permalink: 'whats-new/seen-in-press') }

      it "should use that alias to find a taxon" do
        spree_get :show, :id => 'whats-new-seen-in-press'

        expect(response).to redirect_to spree.nested_taxons_path('whats-new/seen-in-press')
        expect(response.status).to eq 301 #:moved_permanently
      end
    end

    context "when a matching taxon page is not found" do
      it "redirects to root_url with a temporary redirect" do
        spree_get :show, :id => 'non-existent/path'

        expect(response).to redirect_to spree.root_path
        expect(response.status).to eq 307 #:temporary_redirect
      end
    end
  end

end
