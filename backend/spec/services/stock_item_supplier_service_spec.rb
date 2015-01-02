require 'spec_helper'

describe Spree::StockItemSupplierService do
  subject { Spree::StockItemSupplierService.run(variant: variant, supplier_id: supplier_id) }

  let(:supplier) { create(:supplier) }
  let(:supplier_id) { supplier.id.to_s }
  let(:variant) { create(:variant) }

  describe "::run" do

    context "requires supplier" do

      before { Spree::StockItemSupplierService.any_instance.stub requires_supplier: true }

      it "returns the supplier" do
        expect(subject.valid?).to be true
        expect(subject.result).to eq(supplier)
      end

      context "No supplier supplied" do

        let(:supplier_id) { nil }

        it "provides an error" do
          expect(subject.valid?).to be false
          expect(subject.errors.full_messages.to_sentence).to eq "Supplier is required"
        end

      end


    end

    context "does not require supplier" do

      before { Spree::StockItemSupplierService.any_instance.stub requires_supplier: false }


      it "does not return the supplier" do
        expect(subject.valid?).to be true
        expect(subject.result).to be_nil
      end

      context "No supplier supplied" do

        let(:supplier_id) { nil }

        it "does not return the supplier" do
          expect(subject.valid?).to be true
          expect(subject.result).to be_nil
        end

      end

    end

  end
end

#      before { variant.stub_chain(:variant, :product, :product_type, :is_operational).and_return(true)}
#
#      it "does not require a supplier" do
#        expect(subject.valid?).to be true
#        expect(subject.result).to be_nil
#      end

