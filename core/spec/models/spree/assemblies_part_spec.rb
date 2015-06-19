require "spec_helper"

module Spree
  describe StaticAssembliesPart do
    let(:product) { create(:product, id: 123) }
    let(:part) { create(:variant) }
    let(:variant) { create(:variant, id: 123) }

    describe "touching" do
      before do
        product.static_parts.push part
        variant.static_parts.push part
      end

      it "updates a product" do
        ap1 = Spree::StaticAssembliesPart.where(
          part_id: part.id, assembly_id: product.id, assembly_type: "Spree::Product").first
        product.update_column(:updated_at, 1.day.ago)
        ap1.touch
        expect(product.reload.updated_at).to be_within(3.seconds).of(Time.now)
      end

      it "updates a variant" do
        ap2 = Spree::StaticAssembliesPart.where(
          part_id: part.id, assembly_id: variant.id, assembly_type: "Spree::Variant").first
        variant.update_column(:updated_at, 1.day.ago)
        ap2.touch
        expect(variant.reload.updated_at).to be_within(3.seconds).of(Time.now)
      end
    end
  end
end
