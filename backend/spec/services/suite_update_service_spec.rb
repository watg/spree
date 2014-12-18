require 'spec_helper'

describe Spree::SuiteUpdateService do
  subject { Spree::SuiteUpdateService.run(suite: suite, params: params) }

  let(:suite) { create(:suite) }
  let(:taxon) { create(:taxon) }
  let(:taxon_child) { create(:taxon) }
  let(:taxon_childs_child) { create(:taxon) }

  let(:params) { Hash.new }

  before do
    taxon.children << taxon_child
    taxon_child.children << taxon_childs_child
    suite.taxons = [ taxon, taxon_child ] 
  end

  describe "run" do
    subject { Spree::SuiteUpdateService.run(suite: suite, params: params) }

    it "returns valid if correct params" do
      expect(subject.valid?).to be_true
    end

    context "adding" do
      let!(:params) { { taxon_ids: [taxon.id, taxon_child.id, taxon_childs_child.id] } }

      it "adds the taxon suite to the ancestors unless already there" do
        expect(subject.valid?).to be_true
        expect(taxon_child.suites.select { |s| s == suite }.size).to eq 1
        expect(taxon.suites.reload.select { |s| s == suite }.size).to eq 1
      end

      context "anscstor already has suite" do

        before do
          Spree::Classification.create( taxon: taxon_child, suite: suite)
        end

        it "does not duplicate the classification" do
          expect(taxon_child.suites.select { |s| s == suite }.size).to eq 1
          expect(taxon.suites.reload.select { |s| s == suite }.size).to eq 1
        end

      end
    end

    context "removing" do
      let!(:params) { { taxon_ids: [taxon.id, taxon_child.id] } }

      before do
        suite.taxons << taxon_childs_child  
      end

      context "taxon that has both parent and child is removed" do
        let!(:params) { { taxon_ids: [taxon.id, taxon_childs_child.id] } }

        it "destroys ancestors and descendents classifications" do
          expect(subject.valid?).to be_true
          expect(taxon.suites.count).to eq 0
          expect(taxon_child.suites.count).to eq 0
          expect(taxon_childs_child.suites.count).to eq 0
        end

        context "parent has a identical suite from a diferent child" do
          let(:taxon_child_2) { create(:taxon) }

          before do
            taxon.children << taxon_child_2
            taxon_child_2.suites = [suite]
          end

          it "destroys just the descendents classifications" do
            expect(subject.valid?).to be_true
            expect(taxon.suites.count).to eq 1
            expect(taxon_child.suites.count).to eq 0
            expect(taxon_childs_child.suites.count).to eq 0
          end
        end

        context "parent has a different suite in it" do
          let(:suite_2) { create(:suite) }

          before do
            taxon.suites << suite_2 
          end

          it "destroys just the descendents classifications" do
            expect(taxon.suites.count).to eq 2
            expect(subject.valid?).to be_true
            expect(taxon.suites.count).to eq 1
            expect(taxon_child.suites.count).to eq 0
            expect(taxon_childs_child.suites.count).to eq 0
          end
        end

        context "different suite with the same taxons" do
          let(:suite_2) { create(:suite) }

          before do
            suite_2.taxons = [ taxon, taxon_child, taxon_childs_child ] 
          end

          it "should not be affected" do
            expect(subject.valid?).to be_true
            expect(taxon.suites.count).to eq 1
            expect(taxon.suites.detect {|s| s == suite_2}).to be_true
            expect(taxon_child.suites.count).to eq 1
            expect(taxon_child.suites.detect {|s| s == suite_2}).to be_true
            expect(taxon_childs_child.suites.count).to eq 1
            expect(taxon_childs_child.suites.detect {|s| s == suite_2}).to be_true
          end

        end

      end

      context "taxon that is a child of a child is removed" do
        let!(:params) { { taxon_ids: [taxon.id, taxon_child.id] } }

        it "destroys ancestors classifications of parents parent" do
          expect(subject.valid?).to be_true
          expect(taxon.suites.count).to eq 0
          expect(taxon_child.suites.count).to eq 0
        end

        context "parent has a identical suite from a diferent child" do
          let(:taxon_child_2) { create(:taxon) }

          before do
            taxon.children << taxon_child_2
            taxon_child_2.suites = [suite]
          end

          it "destroys just the descendents classifications" do
            expect(subject.valid?).to be_true
            expect(taxon.suites.count).to eq 1
            expect(taxon_child.suites.count).to eq 0
            expect(taxon_childs_child.suites.count).to eq 0
          end
        end

        context "parent has a different suite in it" do
          let(:suite_2) { create(:suite) }

          before do
            taxon.suites << suite_2 
          end

          it "destroys just the descendents classifications" do
            expect(taxon.suites.count).to eq 2
            expect(subject.valid?).to be_true
            expect(taxon.suites.count).to eq 1
            expect(taxon_child.suites.count).to eq 0
            expect(taxon_childs_child.suites.count).to eq 0
          end
        end

        context "different suite with the same taxons" do
          let(:suite_2) { create(:suite) }

          before do
            suite_2.taxons = [ taxon, taxon_child, taxon_childs_child ] 
          end

          it "should not be affected" do
            expect(subject.valid?).to be_true
            expect(taxon.suites.count).to eq 1
            expect(taxon.suites.detect {|s| s == suite_2}).to be_true
            expect(taxon_child.suites.count).to eq 1
            expect(taxon_child.suites.detect {|s| s == suite_2}).to be_true
            expect(taxon_childs_child.suites.count).to eq 1
            expect(taxon_childs_child.suites.detect {|s| s == suite_2}).to be_true
          end

        end

      end

    end

  end

  context "rebuild_suite_tabs_cache" do

    let!(:suite) { build(:suite) }
    let!(:product_1) { build(:base_product) }
    let!(:product_2) { build(:base_product) }
    let!(:tab_1) { build(:suite_tab, product: product_1) }
    let!(:tab_2) { build(:suite_tab, product: product_2) }

    before do
      allow(suite).to receive(:update_attributes!)
      allow_any_instance_of(Spree::SuiteTabCacheRebuilder).to receive(:update_suites)
      suite.tabs = [tab_1, tab_2]
    end

    it "rebuild the cache for each tab" do
      expect(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_product).with(product_1)
      expect(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_product).with(product_2)
      expect(subject.valid?).to be_true
    end

  end


end


