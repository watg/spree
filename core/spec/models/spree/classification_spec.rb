require 'spec_helper'

module Spree
  describe Classification, :type => :model do
    let(:suite) { create(:suite) }
    let(:taxon) { create(:taxon) }

    # Regression test for #3494
    it "cannot link the same taxon to the same suite more than once" do
      add_taxon = lambda { suite.taxons << taxon }
      expect(add_taxon).not_to raise_error
      expect(add_taxon).to raise_error(ActiveRecord::RecordInvalid)
    end

    describe "send_to_top" do
      let(:classification) { Spree::Classification.new(suite: suite, taxon: taxon)}

      it "inserts classification at position 1" do
        expect(classification).to receive(:insert_at).with(1)
        classification.send_to_top
      end
    end

  end
end
