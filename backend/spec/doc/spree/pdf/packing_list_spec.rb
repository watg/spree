require 'spec_helper'

describe Spree::PDF::PackingList do

  let(:order) { create(:completed_order_with_totals) }
  let(:prawn_doc) { Prawn::Document.new }
  let(:pdf) { Spree::PDF::PackingList.new(order) }

  context "with a express order" do
    before { allow(order).to receive(:express?).and_return(true) }
    it "has a express order indication" do
      rendered_pdf = pdf.create.render
      @pdf_content = PDF::Inspector::Text.analyze(rendered_pdf)
      expect(@pdf_content.strings).to include("Express!")
    end
  end

  context "with a regular order" do
    before { allow(order).to receive(:express?).and_return(false) }
    it "does not have a express order indication" do
      rendered_pdf = pdf.create.render
      @pdf_content = PDF::Inspector::Text.analyze(rendered_pdf)
      expect(@pdf_content.strings).to_not include("Express!")
    end
  end
end