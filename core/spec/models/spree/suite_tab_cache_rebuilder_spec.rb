require 'spec_helper'

describe Spree::SuiteTabCacheRebuilder do

  let!(:target) { build(:target) }
  let!(:product) { create(:base_product) }
  let!(:suite) { build_stubbed(:suite, target: target) }
  let!(:suite_tab) { create(:suite_tab, product: product, suite: suite) }

  subject { described_class.new(suite_tab) }

  context "rebuild options" do

    it "rebuilds all" do
      expect(subject).to receive(:rebuild_in_stock).once
      expect(subject).to receive(:rebuild_lowest_amounts).once
      subject.rebuild
    end

  end

  context "#rebuild_from_variant" do

    before { Delayed::Worker.delay_jobs = false }
    after { Delayed::Worker.delay_jobs = true }

    it "creates a async job" do
      expect_any_instance_of(described_class).to receive(:rebuild).once

      product.suite_tabs << suite_tab
      described_class.rebuild_from_variant(product.master)
    end

  end

  context "rebuild_in_stock" do

    context "variants and not master" do

      let!(:variant_1) { create(:base_variant, product: product, targets: [target], in_stock_cache: true) }
      let!(:variant_2) { create(:base_variant, product: product, targets: [target], in_stock_cache: false) }

      context "stock available" do

        it "sets in_stock to true if product variants have stock" do
          suite_tab.in_stock_cache = false
          subject.send(:rebuild_in_stock)
          expect(suite_tab.in_stock_cache).to be_true
        end

      end

      context "no stock available" do

        let(:variant_1) { create(:base_variant, product: product, targets: [target], in_stock_cache: false) }

        it "sets in_stock to false if product variants have no stock" do
          suite_tab.in_stock_cache = true
          subject.send(:rebuild_in_stock)
          expect(suite_tab.in_stock_cache).to be_false
        end
      end

      context "targets" do

        let(:another_target) { build_stubbed(:target) }
        let(:variant_1) { create(:base_variant, product: product, targets: [another_target], in_stock_cache: true) }

        it "sets in_stock to false if there are not variants with the chosen target" do
          suite_tab.in_stock_cache = true
          subject.send(:rebuild_in_stock)
          expect(suite_tab.in_stock_cache).to be_false
        end
      end
    end

    context "master but no variants" do

      #let!(:variant_1) { create(:base_variant, product: product, targets: [target], in_stock_cache: true) }
      #let!(:variant_2) { create(:base_variant, product: product, targets: [target], in_stock_cache: false) }

      context "stock available" do

        before do
          product.master.in_stock_cache = true
        end

        it "sets in_stock to true if product variants have stock" do
          suite_tab.in_stock_cache = false
          subject.send(:rebuild_in_stock)
          expect(suite_tab.in_stock_cache).to be_true
        end
      end

      context "stock not available" do

        before do
          product.master.in_stock_cache = false
        end

        it "sets in_stock to true if product variants have stock" do
          suite_tab.in_stock_cache = true
          subject.send(:rebuild_in_stock)
          expect(suite_tab.in_stock_cache).to be_false
        end
      end

    end

  end

  context "rebuild_lowest_amounts" do

    let!(:variant_1) { create(:base_variant, product: product, targets: [target], in_stock_cache: true, amount: 10) }
    let!(:variant_2) { create(:base_variant, product: product, targets: [target], in_stock_cache: true, amount: 20) }

    it "sets the normal amount" do
      suite_tab.set_lowest_normal_amount(123, 'USD')
      subject.send(:rebuild_lowest_amounts)
      expect(suite_tab.lowest_normal_amount('USD')).to eq 10
    end

    context "sale amaount" do
      let!(:variant_1) { create(:variant_in_sale, product: product, targets: [target], in_stock_cache: true, amount: 10, sale_amount: 5) }
      let!(:variant_2) { create(:variant_in_sale, product: product, targets: [target], in_stock_cache: true, amount: 20, sale_amount: 10) }
      let!(:variant_3) { create(:variant, product: product, targets: [target], in_stock_cache: true, amount: 10) }

      # Ensure the lowest priced in sale variant is not picked up if it is not actually in the sale
      before do
        price = variant_3.price_normal_sale_in('USD')
        price.amount = 2
        price.save
      end

      it "sets the sale amount" do
        suite_tab.set_lowest_sale_amount(123, 'USD')
        subject.send(:rebuild_lowest_amounts)
        expect(suite_tab.lowest_sale_amount('USD')).to eq 5
      end
    end

    context "stock" do
      let(:variant_1) { create(:variant_in_sale, product: product, targets: [target], in_stock_cache: false, amount: 10, sale_amount: 5) }
      let(:variant_2) { create(:variant_in_sale, product: product, targets: [target], in_stock_cache: true, amount: 20, sale_amount: 10) }

      it "sets the amount" do
        subject.send(:rebuild_lowest_amounts)
        expect(suite_tab.lowest_normal_amount('USD')).to eq 20
      end

    end

    context "target" do
      let(:another_target) { build(:target) }
      let(:variant_1) { create(:variant_in_sale, product: product, targets: [another_target], in_stock_cache: true, amount: 10, sale_amount: 5) }
      let(:variant_2) { create(:variant_in_sale, product: product, targets: [target], in_stock_cache: true, amount: 20, sale_amount: 10) }

      it "sets the amount" do
        subject.send(:rebuild_lowest_amounts)
        expect(suite_tab.lowest_normal_amount('USD')).to eq 20
      end

    end

  end
end
