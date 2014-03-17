require 'spec_helper'

describe Spree::AssemblyDefinition do
  let(:assembly) { create(:variant) }
  subject { Spree::AssemblyDefinition.create(variant_id: assembly.id)}

  let(:variant_no_stock)  { create(:variant) }
  let(:part1) { Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id, product_id: variant_no_stock.product_id, count: 3) }

  let(:variant) { create(:variant_with_stock_items) }
  let(:part2) { Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id, product_id: variant.product_id, count: 1) }

  before do
    Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: part1.id, variant_id: variant_no_stock.id)
    Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: part2.id, variant_id: variant.id)
  end
  its(:selected_variants_out_of_stock) { should eq( {part1.id => [variant_no_stock.id]} )}
end
