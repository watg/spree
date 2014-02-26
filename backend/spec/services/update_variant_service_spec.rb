# -*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::UpdateVariantService do
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
    subject { Spree::UpdateVariantService }

    it "should invoke success callback when all is good" do
      outcome = subject.run(variant: variant, details: valid_params, prices: prices)

      expect(outcome.errors).to be_nil
      expect(outcome).to be_success
    end

    it "should invoke failure callback on any error" do
      outcome = subject.run(variant: variant, details: "wrong params!", prices: prices)
      expect(outcome).not_to be_success
    end

    it "should return validate_prices failures" do
      bad_prices = prices.dup
      bad_prices[:normal]['GBP'] = '£0'
      outcome = subject.run(variant: variant, details: valid_params, prices: bad_prices)
      expect(outcome).not_to be_success
      expect(outcome.errors.message_list.join(', ')).to eq('amount can not be <= 0 for currency: GBP and normal price')
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

    it "preserves visible product page variants" do
      product_page = create(:product_page) 
      t = create(:target)
      variant.targets = [t]
      ppv = product_page.product_page_variants.create( variant: variant, target: t )
      params = valid_params.dup
      params[:target_ids] = t.id.to_s
      outcome = subject.run(variant: variant, details: params, prices: prices)
      expect(outcome.errors).to be_nil
      expect(outcome).to be_success
      new_ppv = product_page.reload.product_page_variants
      expect(new_ppv).to match_array([ppv])
    end

  end

end
