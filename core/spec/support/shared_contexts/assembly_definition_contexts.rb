shared_context "assembly definition light" do
  let(:product) { Spree::Product.new(name: "My Product", description: "Product Description") }
  let(:variant) { Spree::Variant.new(in_stock_cache: true, number: "V1234", in_stock_cache: true, updated_at: 1.day.ago, product: product) }

  let(:product_part)  { Spree::Product.new() }
  let(:variant_part)  { Spree::Variant.new(number: "V5678", product: product_part, in_stock_cache: true, updated_at: 2.days.ago) }

  let(:assembly_definition) { Spree::AssemblyDefinition.new(variant: variant) }
  let(:adp) { Spree::AssemblyDefinitionPart.new(assembly_definition: assembly_definition, product: product_part, optional: false) }
  let(:adv) { Spree::AssemblyDefinitionVariant.new(assembly_definition_part: adp, variant: variant_part) }

  before(:each) do
    variant.assembly_definition = assembly_definition
    variant_part.assembly_definition_variants << adv
    adp.variants << variant_part
    assembly_definition.parts << adp
  end
end

