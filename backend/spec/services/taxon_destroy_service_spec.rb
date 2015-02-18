require 'spec_helper'

describe Spree::TaxonDestroyService do
  subject { Spree::TaxonDestroyService.run(params) }

  let(:suite) { create(:suite) }
  let(:taxon) { create(:taxon) }
  let(:taxon_child) { create(:taxon) }
  let(:taxon_childs_child) { create(:taxon) }

  let(:params) { { taxon: taxon_child } }

  before do
    taxon.suites = [ suite ]
    taxon_child.suites = [ suite ]
    taxon_childs_child.suites = [ suite ]
    taxon.children << taxon_child
    taxon_child.children << taxon_childs_child
  end

  context "taxon to delete has a parent and child" do

    it "removes suite from ancestors" do
      expect(subject.valid?).to be true
      expect(taxon.suites.reload.select { |s| s == suite }.size).to eq 0
    end

    it "deletes the child taxons" do
      expect(subject.valid?).to be true
      expect(taxon_childs_child.reload.deleted_at).to_not be_nil
    end

    it "deletes suites associated with self and children" do
      expect(subject.valid?).to be true
      expect(taxon_child.suites.size).to eq 0
      expect(taxon_childs_child.suites.size).to eq 0
    end
  end

  context "ancestor has another child with the same suite" do
    let(:another_taxon_child) { create(:taxon) }

    before do
      another_taxon_child.suites = [suite]
      taxon.children << another_taxon_child
    end

    it "does not removes suite from ancestors" do
      expect(taxon.suites.reload.select { |s| s == suite }.size).to eq 1
      expect(subject.valid?).to be true
      expect(taxon.suites.reload.select { |s| s == suite }.size).to eq 1
    end

  end

end
