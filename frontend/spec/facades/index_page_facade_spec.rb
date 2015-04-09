require "spec_helper"
require_relative "../modules/indexable_shared_examples"

describe IndexPageFacade do
  let(:taxon) { nil }
  let(:context) do
    {
      device: :tablet,
      currency: "USD"
    }
  end

  subject { described_class.new(context: context, taxon: taxon) }

  it_behaves_like IndexableInterface

  describe "#suites" do
    let(:taxon) { create(:taxon, :permalink => "test") }

    let(:suite_1) { create(:suite, :with_tab) }
    let(:suite_2) { create(:suite, :with_tab) }
    let(:suite_3) { create(:suite, :with_tab) }

    before do
      suite_1.taxons << taxon
      suite_2.taxons << taxon
      suite_3.taxons << taxon
    end

    it "assigns @suites to the suites, which belong to a taxon" do
      expect(subject.suites).to eq ([ suite_1, suite_2, suite_3])
    end

    it "only returns the number of suites required by per_page" do
      subject.instance_variable_set("@per_page", 1)
      expect(subject.suites.size).to eq 1
    end

    it "loads the first page if the request page does not contain any suites" do
      subject.instance_variable_set("@per_page", 10)
      subject.instance_variable_set("@page", 2)
      expect(subject.suites.size).to eq 3
    end

    it "does not return suites that have no tabs" do
      suite_3.tabs = []
      expect(subject.suites.size).to eq 2
    end
  end

  describe "#num_pages" do
    it "returns the correct number of pages" do
      allow(subject).to receive(:fetch_suites).and_return([1,2,3,4])
      allow(subject).to receive(:per_page).and_return(3)
      expect(subject.num_pages).to eq 2
    end
  end
end
