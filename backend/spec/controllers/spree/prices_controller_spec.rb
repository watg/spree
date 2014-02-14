# -*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::Admin::PricesController, type: :controller do
  stub_admin_user
  let(:product) { FactoryGirl.create(:product_with_variants, product_type: :part) }
  let(:outcome) { OpenStruct.new(:success? => true) }
  
  context "#update" do
    let(:params) { build_valid_params }

    it "should call variant prices service" do
      Spree::VariantPricesService.should_receive(:run).with(params).and_return(outcome)

      spree_post :create, params.merge(product_id: product.permalink)
    end

    it "should call variant prices service with nil in_sale" do
      expected_params = params.merge(in_sale: [])
      Spree::VariantPricesService.should_receive(:run).with(expected_params).and_return(outcome)
      spree_post :create, params.merge(product_id: product.permalink, in_sale: nil)
    end

  end

  # ---------------------------
  def build_valid_params
    {
      product: product,
      vp: {
        product.variants[0].id =>{
          'normal' => {'USD' => "$22.00", 'EUR' => "€19.00", 'GBP' => "£15.50"}, 
          'sale' =>   {'USD' => "$0.00",  'EUR' => "€0.00",  'GBP' => "£0.00"}, 
          'part' =>   {'USD' => "$22.00", 'EUR' => "€19.00", 'GBP' => "£15.50"}
        }, 
        product.variants[0].id=>{
          'normal' => {'USD' => "$22.00", 'EUR' => "€19.00", 'GBP' => "£15.50"}, 
          'sale' =>  {'USD' => "$0.00",  'EUR' => "€0.00",  'GBP' => "£0.00"}, 
          'part' =>  {'USD' => "$22.00", 'EUR' => "€19.00", 'GBP' => "£15.50"}
        }
      },
      in_sale: [product.variants[0].id.to_s],
      commit: nil,
    }  
  end  
end 
