#-*- coding: utf-8 -*-
require "spec_helper"

describe Spree::ServiceTrait::Prices do
  let(:product) do
    FactoryGirl.create(:product)
  end
  let(:gbp_price) do
    create(:price,
           currency: "GBP",
           amount: 12,
           sale_amount: 2,
           part_amount: 1,
           variant: variant)
  end
  let(:usd_price) do
    create(:price,
           currency: "USD",
           amount: 13,
           sale_amount: 3,
           part_amount: 1,
           variant: variant)
  end
  let(:eur_price) do
    create(:price,
           currency: "EUR",
           amount: 14,
           sale_amount: 4,
           part_amount: 1,
           variant: variant)
  end

  let!(:variant) { FactoryGirl.create(:base_variant, product_id: product.id) }

  before do
    variant.prices.delete_all # delete default price
    variant.prices << gbp_price
    variant.prices << eur_price
    variant.prices << usd_price
  end

  let(:new_prices) do
    {
      normal: { "GBP" => "£39.00", "USD" => "$49.00", "EUR" => "€47.00" },
      normal_sale: { "GBP" => "£111.00", "USD" => "$12.00", "EUR" => "€0.00" },
      part: { "GBP" => "£22.00", "USD" => "$11.00", "EUR" => "€11.00" }
    }
  end

  let(:dummy_class) {  OpenStruct.new.extend(described_class) }

  describe "#update_prices" do
    it "sets the prices on a variant" do
      dummy_class.update_prices(new_prices, variant)
      expect(variant.prices.size).to eq(3)
      expect(variant.price_for_type(:normal, "GBP").amount).to eq(39.00)
      expect(variant.price_for_type(:normal, "USD").amount).to eq(49.00)
      expect(variant.price_for_type(:normal, "EUR").amount).to eq(47.00)

      expect(variant.price_for_type(:normal_sale, "GBP").amount).to eq(111.00)
      expect(variant.price_for_type(:normal_sale, "USD").amount).to eq(12.00)
      expect(variant.price_for_type(:normal_sale, "EUR").amount).to eq(0.00)

      expect(variant.price_for_type(:part, "GBP").amount).to eq(22.00)
      expect(variant.price_for_type(:part, "USD").amount).to eq(11.00)
      expect(variant.price_for_type(:part, "EUR").amount).to eq(11.00)
    end
  end

  describe "#validate_prices" do
    it "accepts valid prices" do
      expect(dummy_class).not_to receive(:add_error)
      dummy_class.validate_prices(new_prices)
    end

    it "does not accept missing currencies for normal" do
      expect(dummy_class).to receive(:add_error)
        .with(:variant, :price, "price not set for type: normal, currency: GBP")
      new_prices[:normal].delete "GBP"
      dummy_class.validate_prices(new_prices)
    end

    it "does accept missing currencies for other price types" do
      expect(dummy_class).not_to receive(:add_error)
      new_prices[:normal_sale].delete "GBP"
      dummy_class.validate_prices(new_prices)
    end

    it "does not accept 0 amount for normal price" do
      expect(dummy_class).to receive(:add_error)
        .with(:variant, :price, "amount can not be <= 0 for type: normal, currency: GBP")
      new_prices[:normal]["GBP"] = "£0"
      dummy_class.validate_prices(new_prices)
    end

    context "part prices" do
      it "does not accept missing currencies" do
        expect(dummy_class).to receive(:add_error)
          .with(:variant, :price, "price not set for type: part, currency: GBP")
        new_prices[:part].delete "GBP"
        dummy_class.validate_prices(new_prices)
      end

      it "does not accept 0 amount" do
        expect(dummy_class).to receive(:add_error)
          .with(:variant, :price, "amount can not be <= 0 for type: part, currency: GBP")
        new_prices[:part]["GBP"] = "£0"
        dummy_class.validate_prices(new_prices)
      end
    end
  end
end
