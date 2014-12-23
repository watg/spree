require 'spec_helper'

describe Spree::TaxonsController do
  # Fix when implementing search
  # it "should provide the current user to the searcher class" do
  #   taxon = create(:taxon, :permalink => "test")
  #   user = mock_model(Spree.user_class, :last_incomplete_spree_order => nil, :spree_api_key => 'fake')
  #   controller.stub :spree_current_user => user
  #   Spree::Config.searcher_class.any_instance.should_receive(:current_user=).with(user)
  #   spree_get :show, :id => taxon.permalink
  #   response.status.should == 200
  # end

  describe "#show" do
    let(:taxon) { create(:taxon, :permalink => "test") }

    let(:suite_tabs_1) { [ create(:suite_tab) ] }
    let(:suite_tabs_2) { [ create(:suite_tab) ] }
    let(:suite_tabs_3) { [ create(:suite_tab) ] }

    let!(:suite_1) { create(:suite, tabs: suite_tabs_1) }
    let!(:suite_2) { create(:suite, tabs: suite_tabs_2) }
    let!(:suite_3) { create(:suite, tabs: suite_tabs_3) }

    let!(:suites) { [ suite_1, suite_2, suite_3] }

    before do
      suite_1.taxons << taxon
      suite_2.taxons << taxon
      suite_3.taxons << taxon
    end

    it "assigns @suites to the suites, which belong to a taxon" do
      spree_get :show, :id => taxon.permalink

      expect(assigns(:suites)).to eq suites
      expect(response).to render_template(:show)
    end

    it "only returns the number of suites required by per_page" do
      spree_get :show, :id => taxon.permalink, per_page: 1

      expect(assigns(:suites).size).to eq 1
      expect(response).to render_template(:show)
    end

    context "no suites on page" do

      it "loads the first page" do
        spree_get :show, :id => taxon.permalink, per_page: 10, page: 2

        expect(assigns(:suites).size).to eq 3
        expect(response).to render_template(:show)
      end

    end

    context "suite has no tabs" do

      let!(:suite_1) { create(:suite, tabs: suite_tabs_1) }
      let!(:suite_2) { create(:suite, tabs: []) }
      let!(:suite_3) { create(:suite, tabs: []) }

      it "does not return suites that have no tabs" do
        spree_get :show, :id => taxon.permalink, per_page: 3
        expect(assigns(:suites).size).to eq 1
        expect(response).to render_template(:show)
      end

    end

    context "context" do
      it "assigns @context to contain device" do
        spree_get :show, :id => taxon.permalink
        expected = {:currency=>"USD", :device => :desktop}
        expect(assigns(:context)).to eq expected 
      end

      context "mobile" do

        before do
          allow_any_instance_of(ApplicationController).to receive(:device).and_return(:mobile)
        end

        it "assigns mobile as device in the context" do
          spree_get :show, :id => taxon.permalink

          expected = {:currency=>"USD", :device => :mobile}
          expect(assigns(:context)).to eq expected 
        end

      end
    end



  end
end
