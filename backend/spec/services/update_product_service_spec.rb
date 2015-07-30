# -*- coding: utf-8 -*-
require "spec_helper"

describe Spree::UpdateProductService do
  let(:product) { FactoryGirl.create(:product_with_variants) }
  let(:option_types) { [FactoryGirl.create(:option_type, name: "onte"), FactoryGirl.create(:option_type, name: "deux")] }

  let(:valid_params) { { option_type_ids: option_types.map(&:id).join(","),  visible_option_type_ids: [option_types[0]].join(","), name: "test product" } }

  let(:prices) do
    {
      normal: { "GBP" => "£39.00", "USD" => "$49.00", "EUR" => "€47.00" },
      normal_sale: { "GBP" => "£111.00", "USD" => "$12.00", "EUR" => "€0.00" },
      part: { "GBP" => "£22.00", "USD" => "$0.00", "EUR" => "€0.00" }
    }
  end

  context "#run" do
    let(:subject) { described_class }

    it "invokes success callback when all is good" do
      outcome = subject.run(product: product, details: valid_params, prices: prices, stock_thresholds: nil)
      expect(outcome).to be_success
    end

    it "invokes failure callback on any error" do
      outcome = subject.run(product: product, details: "wrong params!", prices: prices, stock_thresholds: nil)
      expect(outcome).not_to be_success
    end

    it "complies to definition" do
      expect_any_instance_of(described_class).to receive(:update_details)
      expect_any_instance_of(described_class).to receive(:option_type_visibility)

      subject.run(product: product, details: {}, prices: prices, stock_thresholds: nil)
    end

    it "sets the prices on the master" do
      expect_any_instance_of(described_class)
        .to receive(:update_prices).once.with(hash_including(prices), product.master)

      subject.run(product: product, details: valid_params, prices: prices, stock_thresholds: nil)
    end

    it "allow nil for prices on the master" do
      outcome = subject.run(product: product, details: valid_params, prices: nil, stock_thresholds: nil)
      expect(outcome).to be_success
    end
  end

  context "#option_type_visibility" do
    let(:product) { FactoryGirl.create(:product_with_option_types) }
    let(:pot) { Spree::ProductOptionType.new }

    it "updates product_option_type with visibility selection" do
      color, lang_id = [product.option_types[0], 99]

      expect(subject).to receive(:make_visible).once

      subject.option_type_visibility(product, [color.id, lang_id].join(","))
    end

    it "removes unselected visible option type"do
      expect(subject).to receive(:reset_visible_option_types).with(product.id, product.option_types.map(&:id))

      subject.option_type_visibility(product, "")
    end
  end

  context "update properties" do
    let(:subject) { described_class }
    it "does not delete product detais" do
      add_option_type_to(product, option_types[0])

      product_options = product.option_types.dup
      product_id = product.id

      outcome = subject.run(product: product, details: properties_params, prices: prices, stock_thresholds: nil)
      product  = Spree::Product.find(product_id)

      expect(outcome).to be_success
      expect(product.option_types).to eq(product_options)
    end
  end

  describe "update stock_thresholds" do
    let(:london) { create(:stock_location) }
    let(:bray) { create(:stock_location) }
    let(:stock_thresholds) do
      {
        london.to_param => 100,
        bray.to_param   => 200
      }
    end

    subject(:service) { described_class }

    it "creates stock thresholds on the master" do
      service.run(product: product, details: valid_params, prices: prices, stock_thresholds: stock_thresholds)
      thresholds = product.master.stock_thresholds
      expect(thresholds.size).to eq(2)
    end

    it "updates thresholds if they already exist" do
      product.master.stock_thresholds.create(
        stock_location: london,
        value:          7
      )

      service.run(product: product, details: valid_params, prices: prices, stock_thresholds: stock_thresholds)
      thresholds = product.master.stock_thresholds

      expect(thresholds.size).to eq(2)
      london_threshold = thresholds.detect { |t| t.stock_location == london }
      expect(london_threshold.value).to eq(100)
    end

    it "sets the correct threshold for each location" do
      service.run(product: product, details: valid_params, prices: prices, stock_thresholds: stock_thresholds)
      thresholds = product.master.stock_thresholds

      london_threshold = thresholds.detect { |t| t.stock_location == london }
      expect(london_threshold.value).to eq(100)

      bray_threshold = thresholds.detect { |t| t.stock_location == bray }
      expect(bray_threshold.value).to eq(200)
    end
  end

  # ----------------------
  def to_list(array = [])
    array.map(&:id).join(",")
  end

  def add_option_type_to(p, opt_type)
    p.update_attributes(option_type_ids: [opt_type.id])
  end

  def properties_params
    {
      product_properties_attributes: {
        "0" => { id: "", property_name: "gender", value: "Women" },
        "1" => { id: "",  property_name: "",       value: "" } }
    }
  end
end
