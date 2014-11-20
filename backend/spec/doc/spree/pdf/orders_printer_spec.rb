require 'spec_helper'

describe Spree::PDF::OrdersPrinter do

  let(:order) { create(:completed_order_with_totals) }
  let(:prawn_doc) { Prawn::Document.new }

  subject { Spree::PDF::OrdersPrinter.new([order]) }

  describe "#print_invoices_and_packing_lists" do

    before do
      allow(Prawn::Document).to receive(:new).and_return(prawn_doc)
      allow(subject).to receive(:create_commercial_invoice).and_return(prawn_doc)
    end

    it "renders a pdf" do
      expect_any_instance_of(Prawn::Document).to receive(:render)
      subject.print_invoices_and_packing_lists
      expect(subject.errors).to be_empty
    end

    context "error occured" do

      before do
        subject.errors = ['foo']
      end

      it "surfaces errors" do
        expect_any_instance_of(Prawn::Document).not_to receive(:render)
        subject.print_invoices_and_packing_lists
        expect(subject.errors).to eq ['foo']
      end

    end

  end
end
