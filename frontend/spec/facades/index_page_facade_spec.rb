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
    let(:taxon) { create(:taxon, permalink: "test") }

    let(:suite_1) { create(:suite, :with_tab) }
    let(:suite_2) { create(:suite, :with_tab) }
    let(:suite_3) { create(:suite, :with_tab) }

    before do
      suite_1.taxons << taxon
      suite_2.taxons << taxon
      suite_3.taxons << taxon
    end

    it "assigns @suites to the suites, which belong to a taxon" do
      expect(subject.suites).to eq [suite_1, suite_2, suite_3]
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
      allow(subject).to receive(:fetch_suites).and_return([1, 2, 3, 4])
      allow(subject).to receive(:per_page).and_return(3)
      expect(subject.num_pages).to eq 2
    end
  end

  describe "#available_suites?" do
    it "returns true if there are available suites" do
      allow(subject).to receive(:fetch_suites).and_return([1])
      expect(subject.available_suites?).to eq true
    end

    it "returns false if there are no available suites" do
      allow(subject).to receive(:fetch_suites).and_return([])
      expect(subject.available_suites?).to eq false
    end
  end

  describe "#meta_title" do
    let(:taxon) { double }
    it "returns the taxon.meta_title if present" do
      allow(taxon).to receive(:meta_title).and_return(:foo)
      expect(subject.meta_title).to eq(:foo)
    end

    it "returns the taxon.title if meta_title not present" do
      allow(taxon).to receive(:meta_title).and_return(nil)
      allow(taxon).to receive(:title).and_return(:foo)
      expect(subject.meta_title).to eq(:foo)
    end
  end

  describe "#title" do
    let(:taxon) { double(title: "Made Unique") }
    it { expect(subject.title).to eq taxon.title }
  end
end
