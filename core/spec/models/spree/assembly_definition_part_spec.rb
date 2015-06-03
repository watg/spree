# encoding: utf-8
require 'spec_helper'

describe Spree::AssemblyDefinitionPart do

  let(:variant)  { create(:base_variant) }
  let(:assembly_product) { variant.product }
  let(:part)  { create(:base_product) }
  let(:colour)   { create(:option_type, name: 'colour', position: 2 )}
  subject { create(:assembly_definition_part, assembly_product: assembly_product, assembly_definition_id: 0, part_product: part, displayable_option_type: colour ) }

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
      expect(subject.add_all_available_variants).to be true
    end

  end

end

