# encoding: utf-8
require 'spec_helper'

describe Spree::AssemblyDefinitionPart do

  let(:variant)  { create(:base_variant) }
  let(:assembly_product) { variant.product }
  let(:part)  { create(:base_product) }
  let(:assembly_definition) { create(:assembly_definition, variant: variant) }
  let(:colour)   { create(:option_type, name: 'colour', position: 2 )}
  subject { create(:assembly_definition_part, assembly_definition: assembly_definition, product: part, displayable_option_type: colour ) }


  context "set_assembly_product" do
    it "set assembly product before create" do
      adp = Spree::AssemblyDefinitionPart.new(assembly_definition_id: assembly_definition.id, product_id: part.id,  displayable_option_type: colour )
      expect(adp.assembly_product).to be_nil
      adp.save
      expect(adp.assembly_product).to_not be_nil
    end
  end

  context "touch" do

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

  context "when add all variants is set to true (default)" do

    it 'sets add_all_available_variants to true by default' do
      expect(subject.add_all_available_variants).to be_true
    end

  end

end

