# -*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::Admin::ProductsController, type: :controller do
  stub_authorization!

  context "#update" do
    let(:product) { create(:product) }
    let(:option_types) {[create(:option_type, name: "color"),create(:option_type, name: "size")]}
    let(:taxons) {[create(:taxon, name: "color"),create(:taxon, name: "size")]}
    let(:params) { to_params(product) }

    let(:prices) { }
    let(:active_location) { create(:stock_location) }

    it "should be successful" do
      spree_put :update, params

      expect(response.status).to eq(302)
      expect(flash[:success]).to_not be_blank
    end

    it "sends the correct data to the service" do
      expect(Spree::UpdateProductService).to receive(:run).with(
        product:          product,
        details:          params["product"],
        prices:           params["prices"],
        stock_thresholds: params["stock_thresholds"],
      ).and_call_original
      spree_put :update, params
    end
  end

  # ------------------------------------------------------

  def to_params(product)
    {
      "id" => product.slug,
      "product" => {
        "name"            => product.name,
        "option_type_ids" => option_types.first.to_param,
      },
      "prices"=>{
        "normal"      => {"GBP"=>"£39.00", "USD"=>"$49.00", "EUR"=>"€47.00"},
        "normal_sale" => {"GBP"=>"£111.00", "USD"=>"$12.00", "EUR"=>"€0.00"},
        "part"        => {"GBP"=>"£22.00", "USD"=>"$0.00", "EUR"=>"€0.00"}
      },
      "stock_thresholds" => { "#{active_location.id}"=>"0" },
    }
  end
end
