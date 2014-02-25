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
    let(:product_page_tab) { create(:product_page_tab) }
    let(:product_page) { product_page_tab.product_page.decorate }
    let(:variant) { build(:variant) }

    context "errors" do
      before :each do
        allow(Spree::ProductPage).to receive(:find_by_permalink!).
          with(product_page.permalink).
          and_return(product_page)
      end

      it "re-directs to the shop page" do
        spree_get :show, :tab => "made-by-the-gang"
        response.status.should == 302
        response.should redirect_to "/shop/"
      end
    end

    context "ready-to-wear" do
      before :each do
        allow(Spree::ProductPage).to receive(:find_by_permalink!).
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
        response.should redirect_to "/shop/"
      end
    end

    context "kit" do

      let(:product_page_3) { create(:product_page_tab_kit).product_page }

      before :each do
        allow(Spree::ProductPage).to receive(:find_by_permalink!).
          with(product_page_3.permalink).
          and_return(product_page_3)
      end

      it "is successful with kit" do
        spree_get :show, :id => product_page_3.permalink, :tab => "kit"
        expect(response).to be_success
        assigns(:product_page).class.should == Spree::ProductPageDecorator 
      end

    end

    context "no_tabs" do

      let(:product_page_2) { create(:product_page ).decorate }

      before :each do
        allow(Spree::ProductPage).to receive(:find_by_permalink!).
          with(product_page_2.permalink).
          and_return(product_page_2)
      end

      it "is successful with no tab " do
        product_page_2.tabs = [] 
        spree_get :show, :id => product_page_2.permalink, :tab => ""
        expect(response).to be_success
        assigns(:product_page).should == product_page_2
      end

    end

  end
end
