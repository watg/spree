require 'spec_helper'

describe Spree::AssemblyDefinition do
  let(:assembly) { create(:variant) }
  let(:assembly_product) { assembly.product }
  let(:option_type) { create(:option_type)}
  subject { Spree::AssemblyDefinition.create(variant_id: assembly.id)}

  context "Stock and Option Values" do

    let(:variant_no_stock)  { create(:variant, option_values: [create(:option_value)] ) }
    let(:part1) { Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id, product_id: variant_no_stock.product_id, count: 3, displayable_option_type: option_type ) }

    let(:variant) { create(:variant_with_stock_items) }
    let(:part2) { Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id, product_id: variant.product_id, count: 1, displayable_option_type: option_type ) }

    before do
      Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: part1.id, variant_id: variant_no_stock.id)
      Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: part2.id, variant_id: variant.id)
    end

    its(:selected_variants_out_of_stock) { should eq( {part1.id => [variant_no_stock.id]} )}
    its(:selected_variants_out_of_stock_option_values) { should eq( {part1.id => [variant_no_stock.option_values.pluck(:id)] } )}
  end

  describe "set_assembly_product" do
    it "set assembly product before create" do
      ad = Spree::AssemblyDefinition.new(variant_id: assembly.id)
      expect(ad.assembly_product).to be_nil
      ad.save
      expect(ad.assembly_product).to_not be_nil
    end
  end

  describe "touch" do

    before { Timecop.freeze }
    after { Timecop.return }

    it "touches assembly product after touch" do
      assembly_product.update_column(:updated_at, 1.day.ago)
      subject.touch
      expect(assembly_product.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

    it "touches assembly product after save" do
      assembly_product.update_column(:updated_at, 1.day.ago)
      subject.touch
      expect(assembly_product.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

  end

end
