require 'spec_helper'

describe Spree::ProductGroup do

  # context "stock control" do
  #   let!(:variant_in_stock) { create(:variant_with_stock_items, product_id: variant.product.id) }

  #   it "returns first variant in stock in the scope of the product group" do
  #     pg = variant.product.product_group
  #     product = create(:product, product_group_id: pg.id)
  #     expect(pg.next_variant_in_stock).to eq(variant_in_stock)
  #   end

  #   it "returns no variant in stock in the scope of the product group if " do
  #     pg = variant.product.product_group
  #     variant_in_stock.is_master = true
  #     variant_in_stock.save

  #     product = create(:product, product_group_id: pg.id)
  #     expect(pg.next_variant_in_stock).to be_nil
  #   end

  # end

end
