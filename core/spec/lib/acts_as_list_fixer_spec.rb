require "spec_helper"

describe ActsAsListFixer do
  let(:taxon) { create(:taxon) }
  let(:suite1) { create(:suite) }
  let(:suite2) { create(:suite) }

  before do
    taxon.suites = [suite1, suite2]
    taxon.classifications[0].update_column(:position, 2)
    taxon.classifications[1].update_column(:position, 4)
  end

  describe "#fix_all_taxon_positions!" do
    it "fixes the position order on all taxons" do
      expect(taxon.classifications.pluck(:position)).to eq([2, 4])

      described_class.fix_all_taxon_positions!
      expect(taxon.classifications.pluck(:position)).to eq([1, 2])
    end
  end
end
