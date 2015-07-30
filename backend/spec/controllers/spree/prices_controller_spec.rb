# -*- coding: utf-8 -*-
require "spec_helper"

describe Spree::Admin::PricesController, type: :controller do
  stub_authorization!
  let(:product) { FactoryGirl.create(:product_with_variants) }
  let(:outcome) { OpenStruct.new(:success? => true) }

  context "#update" do
    let(:params) { build_valid_params }

    it "calls variant prices service" do
      expect(Spree::VariantPricesService).to receive(:run).with(params).and_return(outcome)

      spree_post :create, params.merge(product_id: product.slug)
    end

    it "calls variant prices service with nil in_sale" do
      expected_params = params.merge(in_sale: [])
      expect(Spree::VariantPricesService).to receive(:run).with(expected_params).and_return(outcome)
      spree_post :create, params.merge(product_id: product.slug, in_sale: nil)
    end
  end

  # ---------------------------
  def build_valid_params
    {
      product: product,
      vp: {
        product.variants[0].id => {
          "normal" => { "USD" => "$22.00", "EUR" => "€19.00", "GBP" => "£15.50" },
          "sale" =>   { "USD" => "$0.00",  "EUR" => "€0.00",  "GBP" => "£0.00" },
          "part" =>   { "USD" => "$22.00", "EUR" => "€19.00", "GBP" => "£15.50" }
        },
        product.variants[0].id => {
          "normal" => { "USD" => "$22.00", "EUR" => "€19.00", "GBP" => "£15.50" },
          "sale" =>  { "USD" => "$0.00",  "EUR" => "€0.00",  "GBP" => "£0.00" },
          "part" =>  { "USD" => "$22.00", "EUR" => "€19.00", "GBP" => "£15.50" }
        }
      },
      in_sale: [product.variants[0].id.to_s],
      commit: nil
    }
  end
end
