# -*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::Admin::ProductsController, type: :controller do
  stub_authorization!

  context "#update" do
    let(:product) { create(:product) }
    let(:option_types) {[create(:option_type, name: "color"),create(:option_type, name: "size")]}
    let(:taxons) {[create(:taxon, name: "color"),create(:taxon, name: "size")]}
    let(:params) { to_params(product) }

    it "should be successful" do
      spree_put :update, params

      expect(response.status).to eq(302)
      expect(flash[:success]).to_not be_blank
    end
  end


  context "#create_assembly_definition" do
    let(:product) { create(:product_with_variants, product_type: create(:product_type_kit)) }
    let(:params) { { id: product.slug } }
    let(:variant) { product.variants.first}
    let!(:assembly_definition) { create(:assembly_definition, variant: variant) }

    it "should not delete any variants which have an assembly defintiion" do

      spree_put :create_assembly_definition, params

      expect(response.status).to eq(302)
      expect(product.master.assembly_definition).not_to be_nil
      expect(product.variants.size).to eq(1)
      expect(product.variants.first).to eq variant
    end

  end


  # ------------------------------------------------------

  def to_params(product)
    {
      id: product.slug,
      product: {
        name: product.name,
        option_type_ids: option_types.first.id,
      },
      "prices"=>{"normal"=>{"GBP"=>"£39.00", "USD"=>"$49.00", "EUR"=>"€47.00"}, "normal_sale"=>{"GBP"=>"£111.00", "USD"=>"$12.00", "EUR"=>"€0.00"}, "part"=>{"GBP"=>"£22.00", "USD"=>"$0.00", "EUR"=>"€0.00"}, "part_sale"=>{"GBP"=>"£0.00", "USD"=>"$0.00", "EUR"=>"€0.00"}
      }
    }
  end
end
