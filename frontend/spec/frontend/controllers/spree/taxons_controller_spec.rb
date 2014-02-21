require 'spec_helper'

describe Spree::TaxonsController, type: :controller do
  let!(:taxon) { create(:taxon, permalink: 'women/hats-and-scarves') }
  let(:taxon_with_ansectors) { create(:taxon, permalink: 'one/two') }

  before do
    user = mock_model(Spree.user_class, :last_incomplete_spree_order => nil, :spree_api_key => 'fake')
    subject.stub :spree_current_user => user
  end

  if Flip.product_pages?
    it "redirects old taxon show page to index_pages_controller" do
      spree_get :show, :id => 'women/hats-and-scarves'
      expect(response.status).to eq(301)
      expect(response).to redirect_to('/shop/knitwear/women')
    end
  else
  it "should provide the taxon if a valid permalink" do
    allow(Spree::Taxon).to receive(:find_by_permalink) { taxon }
    spree_get :show, :id => taxon.permalink
    response.status.should == 200
    assigns(:taxon).should == taxon 
  end

  it "should provide a redirect if not a valid permalink" do
    allow(Spree::Taxon).to receive(:find_by_permalink) { nil }
    spree_get :show, :id => taxon.permalink
    response.status.should == 302
    response.should redirect_to '/shop/t/'
  end


  it "should provide a redirect if not a valid permalink with ansectors" do
    allow(Spree::Taxon).to receive(:find_by_permalink) { nil }
    spree_get :show, :id => taxon_with_ansectors.permalink
    response.status.should == 302
    response.should redirect_to '/shop/t/one'
  end
  end
end
