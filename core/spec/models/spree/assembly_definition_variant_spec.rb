# encoding: utf-8
require 'spec_helper'

describe Spree::AssemblyDefinitionVariant do

  let(:variant)  { create(:base_variant) }
  let(:product) { variant.product }
  let(:part)  { create(:base_product) }
  let(:adp) { create(:assembly_definition_part, adp_opts) }
  let(:adp_opts) { { product: product, part: part } }

  let(:variant_part)  { create(:base_variant) }
  subject { create(:assembly_definition_variant, assembly_definition_part: adp, variant: variant_part) }

  context "touch" do

    before { Timecop.freeze }
    after { Timecop.return }

    it "touches assembly product after touch" do
      product.update_column(:updated_at, 1.day.ago)
      subject.touch
      expect(product.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

    it "touches assembly product after save" do
      product.update_column(:updated_at, 1.day.ago)
      subject.save
      expect(product.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

  end
end

