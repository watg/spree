shared_context "assembly definition light" do
  let(:product) { Spree::Product.new(name: "My Product", description: "Product Description") }

  let(:variant) do
    Spree::Variant.new(
      in_stock_cache: true,
      product: product
    )
  end

  let(:product_part) { Spree::Product.new }

  let(:variant_part) do
    Spree::Variant.new(
      product: product_part,
      in_stock_cache: true
    )
  end
end
