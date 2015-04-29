require 'spec_helper'

describe Spree::PDF::PackingList do

  let(:order) { create(:completed_order_with_totals) }
  let(:prawn_doc) { Prawn::Document.new }
  let(:pdf) { Spree::PDF::PackingList.new(order) }
  subject do
    rendered_pdf = pdf.create.render
    PDF::Inspector::Text.analyze(rendered_pdf)
  end
  context "with a express order" do
    before { allow(order).to receive(:express?).and_return(true) }
    it "has a express order indication" do
      expect(subject.strings).to include("Express!")
    end
  end

  context "with a regular order" do
    before { allow(order).to receive(:express?).and_return(false) }
    it "does not have a express order indication" do
      expect(subject.strings).to_not include("Express!")
    end
  end
end