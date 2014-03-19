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

end
