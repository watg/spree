# encoding: utf-8
require "spec_helper"

describe Spree::ProductPart do
  subject { create(:product_part, adp_opts) }
  let(:adp_opts) { { product: product, part: part } }
  let(:variant)  { create(:base_variant) }
  let(:product)  { variant.product }
  let(:part)     { create(:base_product) }
  let(:colour)   { create(:option_type, name: "colour", position: 2) }
  let(:type)     { 'kit' }

  before         { product.product_type.update_column(:name, type) }

  describe "save" do
    let(:adp) { create(:product_part, part: part, product: product) }
    it        { expect(adp.product).to eq product }

    context "position" do
      it "respects the last parts position" do
        adp_position = adp.position
        pp = product.product_parts.create
        expect(pp.position).to eq adp_position + 1
      end
    end

    context 'ready made product' do
      subject      { described_class.create(opts) }
      let(:opts)   { { product_id: product.id, optional: "false"} }
      let(:errors) { subject.errors.full_messages }
      let(:type)   { 'normal' }

      it           { expect(errors).to eq(["Optional can't be blank"]) }
    end
  end

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
      subject.touch
      expect(product.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end
  end

  context "when add all variants is set to true (default)" do
    it "sets add_all_available_variants to true by default" do
      expect(subject.add_all_available_variants).to be true
    end
  end
end
