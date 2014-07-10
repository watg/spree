require 'spec_helper'

describe Spree::ShippingManifest do
  let(:order) { create(:order) }
  subject { Spree::ShippingManifest.new(order) }

  # TODO: add more tests with optional parts
  context "creating a hash with aggregated products, quantities and prices" do
    let!(:common_variant) { create(:variant) }
    let!(:line_item_without_parts) { create(:line_item, order: order, variant: common_variant, price: 5.00, quantity: 3) }
    let!(:line_item_with_parts) { create(:line_item, order: order, price: 12.00, quantity: 4) }

    let!(:part1) { create(:line_item_part, line_item: line_item_with_parts, quantity: 1, price: 8.0) }
    let!(:part2) { create(:line_item_part, line_item: line_item_with_parts, quantity: 1, variant: common_variant, price: 12.0) }

    before do
      order.updater.update
      order.update_column(:completed_at, Time.now)
    end

    it "outputs the correct hash data" do
      product1 = common_variant.product
      product2 = part1.variant.product

      result = subject.create
      expect(order.item_total.to_f).to eq 63

      expect(result[product1.id][:product]).to eq product1
      expect(result[product1.id][:group]).to eq product1.product_group
      expect(result[product1.id][:quantity]).to eq 7
      expect(result[product1.id][:single_price].to_f).to eq (59.0 / 7).round(2)
      expect(result[product1.id][:total_price].to_f).to eq 59.0

      expect(result[product2.id][:product]).to eq product2
      expect(result[product2.id][:group]).to eq product2.product_group
      expect(result[product2.id][:quantity]).to eq 4
      expect(result[product2.id][:single_price].to_f).to eq eq (4.0 / 4).round(2)
      expect(result[product2.id][:total_price].to_f).to eq 4.0
    end
  end


  context "terms of trade" do
    it "should be DDP when shipping to US" do
      us = create(:country)
      address = create(:ship_address, country: us)
      order.update_column(:ship_address_id, address.id)

      expect(subject.terms_of_trade_code).to eql('DDP')
    end

    it "should be DDU for anything but US" do
      canada = create(:country, iso_name: 'CANADA', name: 'Canada', iso: 'CA', iso3: 'CAN', states_required: false, numcode: 123)
      address = create(:ship_address, country: canada)
      order.update_column(:ship_address_id, address.id)

      expect(subject.terms_of_trade_code).to eql('DDU')
    end
  end

  context "with digital line items" do
    let(:digital_product) { create(:product, product_type: create(:product_type_gift_card)) }
    let!(:digital_line_item) { create(:line_item, variant: digital_product.master, order: order, price: 12.00, quantity: 2) }
    let!(:normal_line_item) { create(:line_item, order: order, price: 8.00, quantity: 2) }

    it "substracts them from the order total" do
      order.updater.update
      expect(order.total.to_f).to eq 40.0
      expect(subject.order_total.to_f).to eq 16.0
    end

    it "does not add them to the products list" do
      order.updater.update
      expect(order.total.to_f).to eq 40.0
      result = subject.create
      expect(result.size).to eq 1
      expect(result[normal_line_item.product.id]).to be_present
      expect(result[digital_product.id]).not_to be_present
    end
  end

end
