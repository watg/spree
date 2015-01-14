require 'spec_helper'
  describe Spree::Api::PinterestController, type: :controller do
    render_views

    let(:suite)   { Spree::Suite.new(target: target, permalink: 'real-suite-permalink') }
    let(:tab)     { Spree::SuiteTab.new(tab_type: 'made-by-the-gang', product: product) }
    let(:product) { Spree::Product.new(name: "My Product", description: "Descipt") }
    let(:variant) { Spree::Variant.new(in_stock_cache: true, number: "V1234") }
    let(:target)  { Spree::Target.new(name: "Women") }

    let(:url) { Spree::Core::Engine.routes.url_helpers.suite_url(id: 'suite-perma', tab: 'made-by-the-gang', variant_id: 'V1234') }

    before do
      stub_authentication!
      suite.tabs << tab
      product.variants_including_master << variant
      variant.current_price_in("GBP").amount = 15.55
      allow(Spree::Suite).to receive(:find_by).with(permalink: 'suite-perma').and_return suite
    end

    describe "show" do
      it "returns a ok response" do
        api_get :show, {url: url}

        expect(json_response["availability"]).to eq "in stock"
        expect(json_response["currency_code"]).to eq "GBP"
        expect(json_response["description"]).to eq "Descipt"
        expect(json_response["price"]).to eq "15.55"
        expect(json_response["product_id"]).to eq "V1234"
        expect(json_response["provider_name"]).to eq "Wool and the Gang"
        expect(json_response["title"]).to eq "My Product #madeunique by The Gang"
        expect(json_response["url"]).to eq "http://www.example.com/product/real-suite-permalink/made-by-the-gang/V1234"
      end
    end
  end
