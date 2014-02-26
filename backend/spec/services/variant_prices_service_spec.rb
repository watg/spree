#-*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::VariantPricesService do
  let(:product) { FactoryGirl.create(:product) }
  let(:variant) { FactoryGirl.create(:variant, product_id: product.id) }
  let(:variant2) { FactoryGirl.create(:variant, product_id: product.id) }

  describe "#run" do

    let(:params) { {
      product: product,
      vp: {
        product.master.id.to_s => :master_prices,
        variant.id.to_s => :variant_prices,
        variant2.id.to_s => :variant_prices 
      }, 
      in_sale: [product.master.id.to_s, variant2.id.to_s],
      commit: commit 
    } } 

    context "when apply all" do

      let(:commit) { 'apply_all' }

      it "sets the prices on all the variants" do
        Spree::VariantPricesService.any_instance.should_receive(:update_prices).once.with(:master_prices ,product.master)
        Spree::VariantPricesService.any_instance.should_receive(:update_prices).once.with(:master_prices,variant)
        Spree::VariantPricesService.any_instance.should_receive(:update_prices).once.with(:master_prices,variant2)
        Spree::VariantPricesService.any_instance.should_receive(:validate_prices).once.with(:master_prices)
        Spree::VariantPricesService.run(params) 
      end

      it "sets in_sale on all variants if master is in_sale " do
        allow_any_instance_of(Spree::VariantPricesService).to receive(:update_prices)
        allow_any_instance_of(Spree::VariantPricesService).to receive(:validate_prices)
        Spree::VariantPricesService.run(params) 
        product.master.reload.in_sale.should == true
        variant.reload.in_sale.should == true
        variant2.reload.in_sale.should == true
      end

      it "sets in_sale on all variants if master is in_sale " do
        params[:in_sale].delete product.master.id.to_s 
        variant.update_attributes(in_sale: true)
        allow_any_instance_of(Spree::VariantPricesService).to receive(:update_prices)
        allow_any_instance_of(Spree::VariantPricesService).to receive(:validate_prices)
        Spree::VariantPricesService.run(params) 
        product.master.reload.in_sale.should == false
        variant.reload.in_sale.should == false
        variant2.reload.in_sale.should == false
      end

    end

    context "when save changes" do

      let(:commit) { nil }

      it "sets the prices on all the variants" do
        Spree::VariantPricesService.any_instance.should_receive(:validate_prices).once.with(:master_prices)
        Spree::VariantPricesService.any_instance.should_receive(:validate_prices).twice.with(:variant_prices)
        Spree::VariantPricesService.any_instance.should_receive(:update_prices).once.with(:master_prices ,product.master)
        Spree::VariantPricesService.any_instance.should_receive(:update_prices).once.with(:variant_prices,variant)
        Spree::VariantPricesService.any_instance.should_receive(:update_prices).once.with(:variant_prices,variant2)
        Spree::VariantPricesService.run(params) 
      end

      it "sets the in_sale on all variants" do
        allow_any_instance_of(Spree::VariantPricesService).to receive(:update_prices)
        allow_any_instance_of(Spree::VariantPricesService).to receive(:validate_prices)
        Spree::VariantPricesService.run(params) 
        product.master.reload.in_sale.should == true
        variant.reload.in_sale.should == false
        variant2.reload.in_sale.should == true
      end

    end
  end
end
