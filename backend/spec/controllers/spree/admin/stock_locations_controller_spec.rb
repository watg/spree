require 'spec_helper'

module Spree
  module Admin
    describe StockLocationsController do
      stub_authorization!

      # Regression for #4272
      context "with no countries present" do
        it "cannot create a new stock location" do
          spree_get :new
          expect(flash[:error]).to eq(Spree.t(:stock_locations_need_a_default_country))
          expect(response).to redirect_to(spree.admin_stock_locations_path)
        end
      end

      context "with a default country present" do
        before do
          country = FactoryGirl.create(:country)
          Spree::Config[:default_country_id] = country.id
        end

        it "can create a new stock location" do
          spree_get :new
          response.should be_success
        end
      end

      context "with a country with the ISO code of 'US' existing" do
        before do
          FactoryGirl.create(:country, iso: 'US')
        end

        it "can create a new stock location" do
          spree_get :new
          response.should be_success
        end
      end

      describe "GET :new" do
        it "assigns a list of existing active locations" do
          active_locations = create_list(:stock_location, 2)
          create_list(:stock_location, 2, active: false) # these shouldn't be counted
          spree_get :new

          existing_locations = assigns[:existing_active_locations]
          expect(existing_locations).to match_array(active_locations)
        end
      end

      describe "GET :edit" do
        let(:stock_location) { create(:stock_location) }

        it "assigns a list of existing locations" do
          other_active_locations = create_list(:stock_location, 2)
          create_list(:stock_location, 2, active: false) # these shouldn't be counted
          spree_get :edit, id: stock_location

          existing_locations = assigns[:existing_active_locations]
          expect(existing_locations).to match_array(other_active_locations)
        end
      end
    end
  end
end
