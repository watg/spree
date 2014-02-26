require 'spec_helper'

  describe Spree::Api::OlapicController, type: :controller do
    render_views

    let!(:product_page) { create(:product_page) }

    let(:attributes) { [:productId, :name, :productUrl, :stockImageUrl, :category] }

    before do
      stub_authentication!
      Spree::ProductPage.any_instance.stub(:banner_url).and_return('foobar')
    end

    context "as a normal user" do
      it "retrieves a list of products" do
        api_get :index
        p = json_response["products"].first
        p.should have_attributes(attributes)
        p["productId"].should == product_page.permalink
        p["name"].should == product_page.name
        p["productUrl"].should == "http://www.example.com//shop/items/#{product_page.permalink}"
        p["stockImageUrl"].should == "http://test.host/images/foobar" 
        p["category"].should == product_page.target.name

        json_response["total_count"].should == 1
        json_response["current_page"].should == 1
        json_response["pages"].should == 1
        json_response["per_page"].should == Kaminari.config.default_per_page
      end

      context "jsonp" do
        it "retrieves a list of products of jsonp" do
          api_get :index, {:callback => 'callback'}
          response.body.should =~ /^callback\(.*\)$/
          response.header['Content-Type'].should include('application/javascript')
        end
      end

    end
  end
