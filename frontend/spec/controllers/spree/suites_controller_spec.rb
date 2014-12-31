require 'spec_helper'

describe Spree::SuitesController do

  describe "#show" do
    let(:suite) { Spree::Suite.new(target: target, permalink: 'suite-permalink') }
    let(:tab1) { Spree::SuiteTab.new(suite: suite, tab_type: 'arbitrary-tab-1', product_id: 1) }
    let(:tab2) { Spree::SuiteTab.new(suite: suite, tab_type: 'arbitrary-tab-2', product_id: 2) }
    let(:target) { Spree::Target.new }

    context "when a suite is found" do

      context "and has tabs" do
        before do
          suite.tabs << tab1
          suite.tabs << tab2
          expect(Spree::Suite).to receive(:find_by!).with(permalink: 'suite-permalink').and_return suite
        end

        it "selects the requested tab when a tab is specified" do
          spree_get :show, id: "suite-permalink", tab: 'arbitrary-tab-2'

          expect(assigns(:suite)).to eq suite
          expect(assigns(:selected_tab)).to eq tab2
          expect(assigns(:context)).to eq ({ currency: "USD", target: target, :device=>:desktop })

          expect(response).to render_template(:show)
        end

        it "selects the first tab when a tab is not specified and redirects" do
          spree_get :show, id: "suite-permalink"
          url = "http://test.host/product/#{suite.permalink}/#{tab1.tab_type}"
          expect(response).to redirect_to(url)
        end
      end

      context "and has no tabs" do

        before do
          expect(Spree::Suite).to receive(:find_by!).with(permalink: 'suite-permalink').and_return suite
          request.env["HTTP_REFERER"] = "where_i_came_from"
        end

        it "redirects back to the current page" do
          spree_get :show, id: "suite-permalink", tab: 'arbitrary-tab-2'
          expect(response).to redirect_to("where_i_came_from")
          expect(flash.notice).to eq Spree.t("the_page_you_requested_no_longer_exists")
        end

        context "has come from an external page" do

          before do
            request.env["HTTP_REFERER"] = nil
          end

          it "redirects back to the root page" do
            spree_get :show, id: "suite-permalink", tab: 'arbitrary-tab-2'
            expect(response).to redirect_to(spree.root_path)
            expect(flash.notice).to eq Spree.t("the_page_you_requested_no_longer_exists")
          end

        end

      end

    end

    context "when a suite is not found" do
      # TODO: check where it redirects to
      it "returns a not_found status" do
        spree_get :show, id: "non-existing-suite-permalink"
        expect(response.status).to eq 404
      end
    end

  end

end
