require "spec_helper"

describe StaticController, type: :controller do
  context "setting currency" do
    let!(:country) { create(:country, iso: "UK") }
    let(:zone) { create(:zone, currency: "GBP") }

    it "works when country and zone exist" do
      Spree::ZoneMember.create(zoneable: country, zone: zone)
      allow(subject).to receive_messages current_country_code: "UK"

      spree_get :home_page
      expect(response.status).to eq(200)
      expect(session[:currency]).to eq "GBP"
    end

    it "defaults to USD when country is found, but no mathing zone exists" do
      allow(subject).to receive_messages current_country_code: "UK"

      spree_get :home_page
      expect(response.status).to eq(200)
      expect(session[:currency]).to eq "USD"
    end

    it "defaults to USD when the country code is not recognized" do
      spree_get :home_page
      expect(response.status).to eq 200
      expect(session[:country_code]).to eq "US"
      expect(session[:currency]).to eq "USD"
    end
  end

  describe "#home_page" do
    let(:country_codes) { "CountryCodeValidator::VALID_COUNTRY_CODES" }

    context "whitelisted country" do
      before do
        stub_const(country_codes, "GBP")
        allow(subject).to receive(:render)
      end

      it "returns country specific homepage" do
        expect(subject).to receive(:render).with("/static/gbp/home_page")
        get :home_page, {},  "country_code" => "GBP"
      end
    end

    context "blacklisted country" do
      before { stub_const(country_codes, "GBP") }

      it "returns default homepage" do
        get :home_page, {},  "country_code" => "AU"
        expect(response).to render_template(/static\/home_page/)
      end
    end
  end

  context "setting country code" do
    before do
      allow_any_instance_of(ApplicationController).to receive_messages(:valid_environment? => true)
    end

    it "sets the correct country code when an exception in raised" do
      allow(subject.request).to receive(:location).and_raise("this error")

      spree_get :home_page
      expect(response.status).to eq 200
      expect(session[:country_code]).to eq "US"
    end

    it "sets the correct country code when one is recognized" do
      allow(subject.request).to receive_messages location: double("Location", country_code: "UK", cache_hit: false)

      spree_get :home_page
      expect(response.status).to eq 200
      expect(session[:country_code]).to eq "UK"
    end

    it "defaults to US when Geocoder is unable to obtain the correct location" do
      allow(subject.request).to receive_messages location: nil

      spree_get :home_page
      expect(response.status).to eq 200
      expect(session[:country_code]).to eq "US"
    end
  end
end
