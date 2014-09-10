require 'spec_helper'

module Spree
  describe AssembliesPart do
    let(:product) { create(:product, :id => 123) }
    let(:part) { create(:variant) }
    let(:variant) { create(:variant, :id => 123) }

    context "validate_prices" do

      before do
        variant.prices.map { |p| p.amount = 0;  p.is_kit=true; p.save }
      end

      it "should provide an error" do
        ap = product.assemblies_parts.create( :part_id => variant.id, :optional => true, :count => 1 )
        expect(ap.errors.any?).to be_true
      end

    end

    describe "touching" do

      before do
        product.parts.push part
        variant.parts.push part
      end

      it "updates a product" do
        ap1 = Spree::AssembliesPart.where(part_id: part.id, assembly_id: product.id, assembly_type: 'Spree::Product').first
        product.update_column(:updated_at, 1.day.ago)
        ap1.touch
        product.reload.updated_at.should be_within(3.seconds).of(Time.now)
      end

      it "updates a variant" do
        ap2 = Spree::AssembliesPart.where(part_id: part.id, assembly_id: variant.id, assembly_type: 'Spree::Variant').first
        variant.update_column(:updated_at, 1.day.ago)
        ap2.touch
        variant.reload.updated_at.should be_within(3.seconds).of(Time.now)
      end

    end
  end
end
