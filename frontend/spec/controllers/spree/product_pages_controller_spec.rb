require 'spec_helper'

describe Spree::ProductPagesController, type: :controller do
  let(:order) { create(:order) }
  let(:currency) { 'GBP' }

  before do
    subject.stub :authorize! => true, :ensure_api_key => true
    subject.stub(:current_order).and_return(order)
    subject.stub(:set_current_order).and_return(order)
  end

  describe "GET show" do
    let(:product_page) { create(:product_page).decorate }
    let(:product_page_tab_kit) { product_page.knit_your_own }
    let(:product_page_tab) { product_page.made_by_the_gang }
    let(:variant) { build(:variant) }

    context "errors" do
      before :each do
        allow(Spree::ProductPage).to receive(:find_by_slug!).
          with(product_page.permalink).
          and_return(product_page)
      end

      it "re-directs to the shop page" do
        spree_get :show, :tab => "made-by-the-gang"
        response.status.should == 302
        response.should redirect_to root_path
      end
    end

    context "ready-to-wear" do
      before :each do
        allow(Spree::ProductPage).to receive(:find_by_slug!).
          with(product_page.permalink).
          and_return(product_page)
      end

    it "is successful with made-by-the-gang" do
      spree_get :show, :id => product_page.permalink, :tab => "made-by-the-gang"
      expect(response).to be_success
      assigns(:product_page).should == product_page
    end

      it "should provide a redirect if not a valid permalink" do
        spree_get :show, :id => product_page.permalink, :tab => "foobar"
        response.status.should == 302
        response.should redirect_to "/shop/items/#{product_page.permalink}/made-by-the-gang"
      end

      it "should provide a redirect if not a valid product_page" do
        spree_get :show, :id => 'fobar', :tab => "kit"
        response.status.should == 302
        response.should redirect_to root_path
      end
    end

    context "kit" do

      it "is successful with kit" do
        spree_get :show, :id => product_page.permalink, :tab => "knit-your-own"
        expect(response).to be_success
        assigns(:product_page).class.should == Spree::ProductPageDecorator
      end

    end

    context "no_tabs" do
      it "is successful with no tab " do
        spree_get :show, :id => product_page.permalink, :tab => ""
        response.status.should == 302
        response.should redirect_to "http://test.host/shop/items/#{product_page.permalink}/made-by-the-gang"
      end

    end

    context '#redirect_to_suites_pages' do
      context 'when Flip suites_feature is on' do
        let(:redirection_service_result) { double(result: {url: 'http://url.com', http_code: 301}) }

        before do
          allow(Flip).to receive(:on?).with(:suites_feature).and_return(true)
        end

        it "uses the SuitePageRedirectionService to redirect to a suite" do
          expect(Spree::SuitePageRedirectionService).to receive(:run).
            with(permalink: 'product-page-permalink', tab: 'made-by-the-gang').
            and_return redirection_service_result

          spree_get :show, :id => 'product-page-permalink', :tab => "made-by-the-gang"
          expect(response).to redirect_to('http://url.com')
          expect(response.status).to eq 301
        end
      end

      context 'when Flip suites_feature is off' do
        before do
          allow(Flip).to receive(:on?).with(:suites_feature).and_return(false)
        end

        it "does not trigger a redirect" do
          expect(Spree::SuitePageRedirectionService).not_to receive(:run)

          spree_get :show, :id => 'product-page-permalink', :tab => "made-by-the-gang"

          # since no product page is found, default behaviour is to redirect to root
          expect(response).to redirect_to spree.root_path
          expect(response.status).to eq 302
        end
      end
    end

  end
end
