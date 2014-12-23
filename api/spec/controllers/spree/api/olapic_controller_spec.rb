require 'spec_helper'

describe Spree::Api::OlapicController, type: :controller do
  render_views

  let(:target) { build(:target) }
  let!(:suite) { create(:suite, target: target) }

  let(:attributes) { [:productId, :name, :productUrl, :stockImageUrl, :category] }

  before do
    stub_authentication!
  end

  context "as a normal user" do
    let(:image) { create(:suite_image) }
    before do
      suite.image = image
    end

    it "retrieves a list of products" do
      api_get :index
      p = json_response["products"].first
      p.should have_attributes(attributes)
      p["productId"].should == suite.permalink
      p["name"].should == suite.title
      p["productUrl"].should == "http://test.host/product/#{suite.permalink}"
      p["stockImageUrl"].should == "http://test.host#{suite.image.attachment.url}"
      p["category"].should == suite.target.name

      json_response["total_count"].should == 1
      json_response["current_page"].should == 1
      json_response["pages"].should == 1
      json_response["per_page"].should == Kaminari.config.default_per_page
    end
  end

  context "with no image" do

    it "should return the place holder" do
      api_get :index
      p = json_response["products"].first
      p.should have_attributes(attributes)
      p["stockImageUrl"].should == "http://test.host/product-group/placeholder-470x600.gif"
    end
  end

  context "jsonp" do
    it "retrieves a list of products of jsonp" do
      api_get :index, {:callback => 'callback'}
      response.body.should =~ /^callback\(.*\)$/
      response.header['Content-Type'].should include('application/javascript')
    end
  end

end
