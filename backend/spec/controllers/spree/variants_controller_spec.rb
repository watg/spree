# -*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::Admin::VariantsController, type: :controller do
  stub_authorization!

  context "#new" do
    let(:london) { create(:stock_location) }
    let(:bray) { create(:stock_location) }

    it "sets the prices on the new variant" do
      product = create(:product_with_prices)
      master = product.master

      spree_get :new, product_id: product.slug

      prices = assigns[:variant].prices
      expect(prices.map(&:amount)).to match_array(master.prices.map(&:amount))
    end

    it "sets the stock thresholds on the new variant" do
      product = create(:base_product)
      master = product.master
      master.stock_thresholds.create(stock_location: london, value: 7)
      master.stock_thresholds.create(stock_location: bray, value: 10)

      spree_get :new, product_id: product.slug

      # Reusable lambda to convert StockLocations into a (location, value) tuple
      mapper = -> (st) { [st.stock_location_id, st.value] }

      # Use the mapper to convert new and original StockLocations
      thresholds = assigns[:variant].stock_thresholds.map(&mapper)
      expected_thresholds = master.stock_thresholds.map(&mapper)

      expect(thresholds).to match_array(expected_thresholds)
    end
  end

  context "#update" do
    let(:variant) { create(:variant) }
    let(:params) { to_params(variant) }

    let(:prices) { }
    let(:active_location) { create(:stock_location) }

    it "should be successful" do
      spree_put :update, params

      expect(response.status).to eq(302)
      expect(flash[:success]).to_not be_blank
    end

    it "sends the correct data to the service" do
      expect(Spree::UpdateVariantService).to receive(:run).with(
        variant:          variant,
        details:          params["variant"],
        prices:           params["prices"],
        stock_thresholds: params["stock_thresholds"],
      ).and_call_original
      spree_put :update, params
    end
  end

  # ------------------------------------------------------

  def to_params(variant)
    {
      "product_id" => variant.product.slug,
      "id"         => variant.to_param,
      "variant" => {
        "sku"             => variant.sku,
        "cost_price"      => "0.00",
        "tax_category_id" => "",
        "label"           => variant.label,
      },
      "prices"=>{
        "normal"      => {"GBP"=>"£39.00", "USD"=>"$49.00", "EUR"=>"€47.00"},
        "normal_sale" => {"GBP"=>"£111.00", "USD"=>"$12.00", "EUR"=>"€0.00"},
        "part"        => {"GBP"=>"£22.00", "USD"=>"$0.00", "EUR"=>"€0.00"},
        "part_sale"   => {"GBP"=>"£0.00", "USD"=>"$0.00", "EUR"=>"€0.00"}
      },
      "stock_thresholds" => { "#{active_location.id}"=>"0" },
    }
  end
end
