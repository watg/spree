# encoding: utf-8
require 'spec_helper'

describe Spree::AssemblyDefinitionPart do
  subject { create(:assembly_definition_part, adp_opts) }
  let(:adp_opts) { { assembly_product: assembly_product, part_product: part } }
  let(:variant)  { create(:base_variant) }
  let(:assembly_product) { variant.product }
  let(:part)  { create(:base_product) }
  let(:colour)   { create(:option_type, name: 'colour', position: 2 )}

  describe 'save' do
    let(:ad)  { build(:assembly_definition, variant: variant) }
    let(:adp) { create(:assembly_definition_part, product_id: part.id, assembly_definition: ad) }
    it        { expect(adp.product).to eq assembly_product }
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
      expect(subject.add_all_available_variants).to be true
    end
  end
end
