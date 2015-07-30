require "spec_helper"

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
      expect(p).to have_attributes(attributes)
      expect(p["productId"]).to eq(suite.permalink)
      expect(p["name"]).to eq(suite.title)
      expect(p["productUrl"]).to eq("http://test.host/product/#{suite.permalink}")
      expect(p["stockImageUrl"]).to eq("http://test.host#{suite.image.attachment.url}")
      expect(p["category"]).to eq(suite.target.name)

      expect(json_response["total_count"]).to eq(1)
      expect(json_response["current_page"]).to eq(1)
      expect(json_response["pages"]).to eq(1)
      expect(json_response["per_page"]).to eq(Kaminari.config.default_per_page)
    end
  end

  context "with no image" do
    it "returns the place holder" do
      api_get :index
      p = json_response["products"].first
      expect(p).to have_attributes(attributes)
      expect(p["stockImageUrl"]).to eq("http://test.host/product-group/placeholder-470x600.gif")
    end
  end

  context "jsonp" do
    it "retrieves a list of products of jsonp" do
      api_get :index, callback: "callback"
      expect(response.body).to match(/^callback\(.*\)$/)
      expect(response.header["Content-Type"]).to include("application/javascript")
    end
  end
end
