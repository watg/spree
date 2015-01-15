# -*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::UpdateVariantService do
  subject { Spree::UpdateVariantService }

  let(:product) { create(:product) }
  let(:variant) { create(:variant, product_id: product.id) }
  let(:variant2) { create(:variant, product_id: product.id) }
  let(:option_type) { create(:option_type, name: "color") }
  let(:option_value) { create(:option_value, option_type: option_type, presentation: 'red') }
  let(:tags) { [create(:tag, value: "First Tag"), create(:tag, value: "Second Tag" )] }
  let(:tag_ids) { tags.map(&:id).join(',') }
  let(:targets) { create_list(:target, 2) }
  let(:target_ids) { targets.map(&:id).join(',') }

  let(:valid_params) {{
     sku: '123123',
     label: 'test',
     option_value_ids: [option_value.id],
     tags: tag_ids,
     target_ids: target_ids
  }}

  let(:prices) { {
    :normal=>{"GBP"=>"£39.00", "USD"=>"$49.00", "EUR"=>"€47.00"},
    :normal_sale=>{"GBP"=>"£111.00", "USD"=>"$12.00", "EUR"=>"€0.00"},
    :part=>{"GBP"=>"£22.00", "USD"=>"$0.00", "EUR"=>"€0.00"},
    :part_sale=>{"GBP"=>"£0.00", "USD"=>"$0.00", "EUR"=>"€0.00"}
  } }

  context "#run" do

    it "should invoke success callback when all is good" do
      outcome = subject.run(variant: variant, details: valid_params, prices: prices)
      expect(outcome.valid?).to be_true
    end

    it "should invoke failure callback on any error" do
      outcome = subject.run(variant: variant, details: "wrong params!", prices: prices)
      expect(outcome.valid?).to be_false
      expect(outcome.errors.full_messages.to_sentence).to eq 'Details is not a valid hash'
    end

    it "should return validate_prices failures" do
      bad_prices = prices.dup
      bad_prices[:normal]['GBP'] = '£0'
      outcome = subject.run(variant: variant, details: valid_params, prices: bad_prices)
      expect(outcome.valid?).to be_false
      expect(outcome.errors.full_messages.to_sentence).to eq 'Variant amount can not be <= 0 for currency: GBP and normal price'
    end

    it "sets the prices on the master" do
      Spree::UpdateVariantService.any_instance.should_receive(:update_prices).once.with(hash_including(prices) ,variant)
      subject.run(variant: variant, details: valid_params, prices: prices)
    end

    it "adds new tags" do
      subject.run(variant: variant, details: valid_params, prices: prices)
      new_tag_values = variant.reload.tags.sort_by(&:value)
      expect(new_tag_values).to match_array(tags)
    end

    it "removes old tags" do
      variant.tags << create(:tag)
      subject.run(variant: variant, details: valid_params, prices: prices)
      new_tag_values = variant.reload.tags.sort_by(&:value)
      expect(new_tag_values).to match_array(tags)
    end

    it "adds new targets" do
      subject.run(variant: variant, details: valid_params, prices: prices)
      new_targets = variant.reload.targets
      expect(new_targets).to match_array(targets)
    end

    it "removes old targets" do
      variant.targets << create(:target)
      subject.run(variant: variant, details: valid_params, prices: prices)
      new_targets = variant.reload.targets
      expect(new_targets).to match_array(targets)
    end

  end

  describe "update stock_thresholds" do
    let(:london) { create(:stock_location) }
    let(:bray) { create(:stock_location) }
    let(:stock_thresholds) { {
      london.to_param => 100,
      bray.to_param   => 200,
    } }

    subject(:service) { Spree::UpdateVariantService }

    it "creates stock thresholds on the master" do
      service.run(variant: variant, details: valid_params, prices: prices, stock_thresholds: stock_thresholds)
      thresholds = variant.stock_thresholds
      expect(thresholds.size).to eq(2)
    end

    it "updates thresholds if they already exist" do
      variant.stock_thresholds.create(
        stock_location: london,
        value:          7
      )

      service.run(variant: variant, details: valid_params, prices: prices, stock_thresholds: stock_thresholds)
      thresholds = variant.stock_thresholds

      expect(thresholds.size).to eq(2)
      london_threshold = thresholds.detect { |t| t.stock_location == london }
      expect(london_threshold.value).to eq(100)
    end

    it "sets the correct threshold for each location" do
      service.run(variant: variant, details: valid_params, prices: prices, stock_thresholds: stock_thresholds)
      thresholds = variant.reload.stock_thresholds

      london_threshold = thresholds.detect { |t| t.stock_location == london }
      expect(london_threshold.value).to eq(100)

      bray_threshold = thresholds.detect { |t| t.stock_location == bray }
      expect(bray_threshold.value).to eq(200)
    end
  end

  context "requires a supplier" do

    let(:supplier) { create(:supplier) }

    before { Spree::ProductType.any_instance.stub requires_supplier?: true }

    context "on create" do

      let(:variant) { build(:variant, product_id: product.id) }

      context "with supplier supplied" do
        before { valid_params.merge!(supplier_id: supplier.id) }

        it "sets the supplier on variant" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.supplier).to eq supplier
        end
      end

      context "no supplier supplied" do

        let(:variant) { build(:variant, product_id: product.id) }

        it "provides an error" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.errors.full_messages.to_sentence).to eq 'Supplier is required'
        end

      end

    end

    context "on update" do

      context "with supplier supplied" do
        before { valid_params.merge!(supplier_id: supplier.id) }
        it "does not set the supplier on variant" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.supplier).to be_nil
        end
      end

      context "no supplier supplied" do

        it "does not provide an error" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.supplier).to be_nil
        end

      end

    end

  end

  context "does not require a supplier" do

    let(:supplier) { create(:supplier) }

    before { Spree::ProductType.any_instance.stub requires_supplier?: false }

    context "on create" do

      let(:variant) { build(:variant, product_id: product.id) }

      context "with supplier supplied" do
        before { valid_params.merge!(supplier_id: supplier.id) }

        it "sets the supplier on variant" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.supplier).to be_nil
        end
      end

      context "no supplier supplied" do

        let(:variant) { build(:variant, product_id: product.id) }

        it "provides an error" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.supplier).to be_nil
        end

      end

    end

    context "set_product_type_defaults" do

      it "sets defaults" do
        outcome = subject.run(variant: variant, details: valid_params, prices: prices)
        expect(outcome.valid?).to be_true
        expect(variant.track_inventory).to be_true
        expect(variant.in_stock_cache).to be_false
      end

      context "when an assembly" do

        before do
          variant.product.product_type.is_assembly = true
        end

        it "sets defaults" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.track_inventory).to be_false
          expect(variant.in_stock_cache).to be_true
        end

      end

    end

    context "on update" do

      context "with supplier supplied" do
        before { valid_params.merge!(supplier_id: supplier.id) }
        it "does not set the supplier on variant" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.supplier).to be_nil
        end
      end

      context "no supplier supplied" do

        it "does not provide an error" do
          outcome = subject.run(variant: variant, details: valid_params, prices: prices)
          expect(outcome.valid?).to be_true
          expect(variant.supplier).to be_nil
        end

      end

    end

  end


end

