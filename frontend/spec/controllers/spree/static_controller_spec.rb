require 'spec_helper'

describe StaticController, type: :controller do

  context "setting currency" do
    let!(:country) { create(:country, iso: "UK") }
    let(:zone) { create(:zone, currency: "GBP") }

    it "works when country and zone exist" do
      Spree::ZoneMember.create(zoneable: country, zone: zone)
      subject.stub :current_country_code => "UK"

      spree_get :home_page
      response.status.should == 200
      expect(session[:currency]).to eq "GBP" 
    end

    it "defaults to USD when country is found, but no mathing zone exists" do
      subject.stub :current_country_code => "UK"

      spree_get :home_page
      response.status.should == 200
      expect(session[:currency]).to eq "USD" 
    end

    it "defaults to USD when the country code is not recognized" do
      spree_get :home_page
      response.status.should == 200
      expect(session[:country_code]).to eq "US"
      expect(session[:currency]).to eq "USD"
    end

  end

  context "setting country code" do
    before do
      ApplicationController.any_instance.stub( :valid_environment? => true )
    end

    it "sets the correct country code when an exception in raised" do
      subject.request.stub(:location).and_raise("this error")

      spree_get :home_page
      response.status.should == 200
      expect(session[:country_code]).to eq "US"
    end


    it "sets the correct country code when one is recognized" do
      subject.request.stub :location => double("Location", :country_code => "UK", :cache_hit => false)

      spree_get :home_page
      response.status.should == 200
      expect(session[:country_code]).to eq "UK"
    end

    it "defaults to US when Geocoder is unable to obtain the correct location" do
      subject.request.stub :location => nil

      spree_get :home_page
      response.status.should == 200
      expect(session[:country_code]).to eq "US"
    end
  end


end
