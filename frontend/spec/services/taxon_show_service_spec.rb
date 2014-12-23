require 'spec_helper'

describe Spree::TaxonShowService do
  subject { Spree::TaxonShowService }


  describe "run" do

    context "taxon exists for permalink" do

      let!(:taxon) { create(:taxon, permalink: 'hey/you/guys') }

      it "returns the taxon" do
        expect(subject.run!(permalink: 'hey/you/guys')).to eq taxon
      end

    end

    context "taxon does not exist" do

      it "returns the taxon" do
        expect(subject.run!(permalink: 'hey/you/guys')).to be_nil
      end

      context "it has a parent taxon that does" do

        let!(:taxon) { create(:taxon, permalink: 'hey/you') }

        it "returns the taxon" do
          expect(subject.run!(permalink: 'hey/you/guys')).to eq taxon
        end

      end

    end

  end
end
