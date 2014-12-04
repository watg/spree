require 'spec_helper'

describe Spree::IndexPagesController, type: :controller do
  let(:index_page) { create(:index_page) }

  before do
    user = mock_model(Spree.user_class, :last_incomplete_spree_order => nil, :spree_api_key => 'fake', :has_spree_role? => false)
    subject.stub :spree_current_user => user
  end

  it "should provide the index page if a valid permalink" do
    spree_get :show, :id => index_page.permalink
    response.status.should == 200
    expect(assigns(:index_page)).to eq index_page
  end

  it "should provide a 404 response if not a valid permalink" do
    spree_get :show, :id => 'non-existing-permalink'
    response.status.should == 404
  end


  describe '#redirect_to_taxon_pages' do
    context 'when Flip suites_feature is on' do
      before do
        allow(Flip).to receive(:on?).with(:suites_feature).and_return(true)
      end

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

    context 'when Flip suites_feature is off' do
      before do
        allow(Flip).to receive(:on?).with(:suites_feature).and_return(false)
      end

      it "does not trigger a redirect" do
        spree_get :show, :id => 'some-index-page-permalink'

        # since no index page is found, default behaviour is to render 404
        expect(response.status).to eq 404
      end
    end
  end


end
