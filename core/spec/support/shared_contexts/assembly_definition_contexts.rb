shared_context "assembly definition light" do
  let(:product) { Spree::Product.new( name: "My Product", description: "Product Description") }
  let(:variant) do
    Spree::Variant.new( in_stock_cache: true, number: "V1234", label: "kit_variant", in_stock_cache: true,
      updated_at: 1.day.ago, product: product )
  end
  let(:product_part) { Spree::Product.new }

  let(:variant_part) do
    Spree::Variant.new(number: "V5678", label: "part_variant", product: product_part, in_stock_cache: true, updated_at: 2.days.ago)
  end

  let(:adp) do
    Spree::AssemblyDefinitionPart.new(assembly_product: product, part_product: product_part, optional: false, assembly_definition_id: 0)
  end

  let(:adv) do
    Spree::AssemblyDefinitionVariant.new( assembly_definition_part: adp, variant: variant_part)
  end

  before(:each) do
    variant.product.extra_parts << adp
    variant_part.assembly_definition_variants << adv
    adp.variants << variant_part
    product.master = variant
    product_part.master = variant_part

  end
end

shared_context "assembly definition" do
  let!(:product) { create(:base_product) }
  let!(:variant) { create(:base_variant, product: product, in_stock_cache: true) }

  let!(:product_part) { create(:base_product) }
  let!(:variant_part) { create(:base_variant, product: product_part) }

  let(:adp) do
    Spree::AssemblyDefinitionPart.new(
       assembly_product_id: product.id, part_product: product_part, optional: false, assembly_definition_id: 0
    )
  end
  let(:adv) do
    Spree::AssemblyDefinitionVariant.new(
      assembly_definition_part: adp, variant: variant_part
    )
  end
  before(:each) do
    adp.save!
    adv.save!
  end
end
