require 'spec_helper'

describe Spree::TaxonUpdateService do
  subject { Spree::TaxonUpdateService.run(params) }

  let(:suite) { create(:suite) }
  let(:taxon) { create(:taxon) }
  let(:taxon_child) { create(:taxon) }
  let(:taxon_childs_child) { create(:taxon) }

  let(:params) { { taxon: taxon, params: Hash.new } }

  before do
    taxon.children << taxon_child
  end

  describe "run" do
    it "returns valid if correct params" do
      expect(subject.valid?).to be_true
    end

    context "adding a taxon with a suite to a parent" do
      let!(:params) { { taxon: taxon_childs_child, params: { parent_id: taxon_child.id } } }

      before do
        taxon_childs_child.suites = [suite]
      end

      it "adds the taxon suite to the ancestors" do
        expect(subject.valid?).to be_true
        expect(taxon.suites.select { |s| s == suite }.size).to eq 1
        expect(taxon_child.suites.select { |s| s == suite }.size).to eq 1
      end

      context "parent has not changed" do
        before do
          taxon_child.children << taxon_childs_child
        end

        it "does not add suites to ancestors if the parent_id has not changed" do
          expect(subject.valid?).to be_true
          expect(taxon.suites.select { |s| s == suite }.size).to eq 0
          expect(taxon_child.suites.select { |s| s == suite }.size).to eq 0
        end

      end

      context "ancestors already has suite" do

        before do
          taxon.suites = [suite]
        end

        it "does not duplicate the classification" do
          expect(subject.valid?).to be_true
          expect(taxon.suites.select { |s| s == suite }.size).to eq 1
          expect(taxon_child.suites.select { |s| s == suite }.size).to eq 1
        end

      end

      context "ancestors already has suite which is different" do
        let!(:suite_2) { create(:suite) }

        before do
          taxon.suites = [suite_2]
        end

        it "does not duplicate the classification" do
          expect(subject.valid?).to be_true
          expect(taxon_child.suites.select { |s| s == suite }.size).to eq 1
          taxon.suites.reload
          expect(taxon.suites.select { |s| s == suite }.size).to eq 1
          expect(taxon.suites.select { |s| s == suite_2 }.size).to eq 1
        end

      end

    end

    context "removing a taxon from parents" do
      let!(:params) { { taxon: taxon_childs_child, params: { parent_id: nil } } }

      before do
        taxon_child.children << taxon_childs_child

        taxon.suites = [suite]
        taxon_child.suites = [suite]
        taxon_childs_child.suites = [suite]

        taxon.reload
        taxon_child.reload
      end

      it "remove the taxon suite from the ancestors" do
        expect(subject.valid?).to be_true
        expect(taxon.suites.select { |s| s == suite }.size).to eq 0
        expect(taxon_child.suites.select { |s| s == suite }.size).to eq 0
      end

      context "parent has not changed" do
        before do
          taxon_childs_child.parent_id = nil 
          taxon_childs_child.save
        end

        it "does not remove suites if the parent_id has not changed" do
          expect(subject.valid?).to be_true
          expect(taxon.suites.select { |s| s == suite }.size).to eq 1
          expect(taxon_child.suites.select { |s| s == suite }.size).to eq 1
        end

      end

      context "multiple suites" do

        let(:suite_2) { create(:suite) }

        before do
          taxon.suites << suite_2
          taxon_child.suites << suite_2
          taxon_childs_child.suites << suite_2

          taxon.reload
          taxon_child.reload
        end

        it "removes multiple suites related with self from its ancestors" do
          expect(taxon.suites.size).to eq 2
          expect(taxon_child.suites.size).to eq 2
          expect(taxon_childs_child.suites.size).to eq 2
          expect(subject.valid?).to be_true
          expect(taxon.suites.size).to eq 0
          expect(taxon_child.suites.size).to eq 0
          expect(taxon_childs_child.suites.size).to eq 2
        end
      end

      context "ancestors already has suite from anohter child" do
        let!(:another_child_taxon) { create(:taxon) }

        before do
          taxon.children << another_child_taxon
          another_child_taxon.suites = [suite]
        end

        it "does not duplicate the classification" do
          expect(taxon.suites.size).to eq 1
          expect(taxon_child.suites.size).to eq 1
          expect(subject.valid?).to be_true
          expect(taxon.suites.size).to eq 1
          expect(taxon_child.suites.size).to eq 0
        end

      end

    end

    context "taxon is moved from one ancestor to another" do
      let!(:another_taxon) { create(:taxon) }
      let!(:params) { { taxon: taxon_childs_child, params: { parent_id: another_taxon.id } } }

      before do
        taxon_child.children << taxon_childs_child

        taxon.suites = [suite]
        taxon_child.suites = [suite]
        taxon_childs_child.suites = [suite]

        taxon.reload
        taxon_child.reload
      end


      it "does not duplicate the classification" do
        expect(taxon_child.reload.suites.select { |s| s == suite }.size).to eq 1
        expect(taxon.suites.reload.select { |s| s == suite }.size).to eq 1
        expect(subject.valid?).to be_true
        expect(another_taxon.reload.suites.select { |s| s == suite }.size).to eq 1
        expect(taxon.suites.reload.select { |s| s == suite }.size).to eq 0
        expect(taxon_child.reload.suites.select { |s| s == suite }.size).to eq 0
        expect(taxon_childs_child.reload.suites.select { |s| s == suite }.size).to eq 1
      end

    end

  end

end
