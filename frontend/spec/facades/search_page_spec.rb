require "spec_helper"
require_relative "../modules/indexable_shared_examples"

describe SearchPage do
  let(:searcher) { instance_double("Search::Base", results: [], num_pages: 3) }

  let(:context) do
    {
      device: :tablet,
      currency: "USD"
    }
  end

  subject { described_class.new(context: context, searcher: searcher) }

  it_behaves_like IndexableInterface

  describe ".suites" do
    it "it brings the searcher results" do
      expect(searcher).to receive(:results)
      subject.suites
    end
  end

  describe ".title" do
    it { expect(subject.title).to eq("Search results") }
  end

  describe ".num_pages" do
    it { is_expected.to respond_to(:num_pages) }
  end
end
