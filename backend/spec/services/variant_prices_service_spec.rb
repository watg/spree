#-*- coding: utf-8 -*-
require "spec_helper"

describe Spree::VariantPricesService do
  let(:product) { FactoryGirl.create(:product) }
  let(:variant) { FactoryGirl.create(:variant, product_id: product.id) }
  let(:variant2) { FactoryGirl.create(:variant, product_id: product.id) }

  let(:commit) { nil }

  describe "#run" do
    let(:params) do
      {
        product: product.reload,
        vp: {
          product.master.id.to_s => :master_prices,
          variant.id.to_s => :variant_prices,
          variant2.id.to_s => :variant_prices
        },
        in_sale: [product.master.id.to_s, variant2.id.to_s],
        commit: commit
      }
    end

    before do
      allow(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_product_async)
    end

    context "suite tab cache rebuilder" do
      it "get's called" do
        expect(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_product_async).with(product)
        allow_any_instance_of(described_class).to receive(:update_prices)
        allow_any_instance_of(described_class).to receive(:validate_prices)
        described_class.run(params)
      end
    end

    context "when apply all" do
      let(:commit) { "apply_all" }

      it "sets the prices on all the variants" do
        expect_any_instance_of(described_class).to receive(:update_prices).once.with(:master_prices, product.master)
        expect_any_instance_of(described_class).to receive(:update_prices).once.with(:master_prices, variant)
        expect_any_instance_of(described_class).to receive(:update_prices).once.with(:master_prices, variant2)
        expect_any_instance_of(described_class).to receive(:validate_prices).once.with(:master_prices)
        described_class.run(params)
      end

      it "sets in_sale on all variants if master is in_sale " do
        allow_any_instance_of(described_class).to receive(:update_prices)
        allow_any_instance_of(described_class).to receive(:validate_prices)
        described_class.run(params)
        expect(product.master.reload.in_sale).to eq(true)
        expect(variant.reload.in_sale).to eq(true)
        expect(variant2.reload.in_sale).to eq(true)
      end

      it "sets in_sale on all variants if master is in_sale " do
        params[:in_sale].delete product.master.id.to_s
        variant.update_attributes(in_sale: true)
        allow_any_instance_of(described_class).to receive(:update_prices)
        allow_any_instance_of(described_class).to receive(:validate_prices)
        described_class.run(params)
        expect(product.master.reload.in_sale).to eq(false)
        expect(variant.reload.in_sale).to eq(false)
        expect(variant2.reload.in_sale).to eq(false)
      end
    end

    context "when save changes" do
      let(:commit) { nil }

      it "sets the prices on all the variants" do
        expect_any_instance_of(described_class).to receive(:validate_prices).once.with(:master_prices)
        expect_any_instance_of(described_class).to receive(:validate_prices).twice.with(:variant_prices)
        expect_any_instance_of(described_class).to receive(:update_prices).once.with(:master_prices, product.master)
        expect_any_instance_of(described_class).to receive(:update_prices).once.with(:variant_prices, variant)
        expect_any_instance_of(described_class).to receive(:update_prices).once.with(:variant_prices, variant2)
        described_class.run(params)
      end

      it "sets the in_sale on all variants" do
        allow_any_instance_of(described_class).to receive(:update_prices)
        allow_any_instance_of(described_class).to receive(:validate_prices)
        described_class.run(params)
        expect(product.master.reload.in_sale).to eq(true)
        expect(variant.reload.in_sale).to eq(false)
        expect(variant2.reload.in_sale).to eq(true)
      end
    end
  end
end
