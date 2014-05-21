require 'spec_helper'

describe Spree::ShippingManifest do
  let(:order) { create(:order) }
  let!(:common_variant) { create(:variant) }
  let!(:line_item_without_parts) { create(:line_item, order: order, variant: common_variant, price: 5.00, quantity: 3) }
  let!(:line_item_with_parts) { create(:line_item, order: order, price: 12.00, quantity: 4) }

  let!(:part1) { create(:line_item_part, line_item: line_item_with_parts, quantity: 1, price: 8.0) }
  let!(:part2) { create(:line_item_part, line_item: line_item_with_parts, quantity: 1, variant: common_variant, price: 12.0) }


  before do
    order.updater.update
    order.update_column(:completed_at, Time.now)

  end

  # add more tests and comments in the shipping manifest
  it "outputs a hash with aggregated products, quantities and prices" do
    result = Spree::ShippingManifest.new(order).create
    
    product1 = common_variant.product
    product2 = part1.variant.product

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