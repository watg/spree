require 'spec_helper'
describe Api::Search::PredictableSearch do

  let!(:product){ create(:product, description: "hats for everione") }
  let!(:hats_suite_1) { create(:suite, title: "Hats for test") }
  let!(:hats_suite_2) { create(:suite, title: "Hats for me too") }
  let!(:caps_suite) { create(:suite, title: "I prefer caps") }
  let!(:hats_suite_without_tabs) { create(:suite, title: "Hats - inactive") }
  let!(:taxon) { create(:taxon, name: "the hats taxon") }
  let!(:suite_tab1) { create(:suite_tab, suite: hats_suite_1, product: product) }
  let!(:suite_tab2) { create(:suite_tab, suite: hats_suite_2, product: product) }
  let!(:suite_tab3) { create(:suite_tab, suite: caps_suite, product: product) }
  let(:view_context) { double(:url_for => 'test_link') }
  before do
    hats_suite_1.taxons << taxon
    hats_suite_2.taxons << taxon
    caps_suite.taxons << taxon
    hats_suite_without_tabs.taxons << taxon
  end

  context "with valid keywords" do
    describe ".search" do
      subject {described_class.new("hat", view_context).results}
      it "returns suites with title that matches the name" do
        expect(subject.length).to eq(2)
        expect(subject).to include({title: "Hats for test", url: "test_link"})
        expect(subject).to include({title: "Hats for me too", url: "test_link"})
      end

      it "not return suites with title does not match the search" do
        expect(subject.length).to eq(2)
        expect(subject).to_not include ({title: "I prefer caps", url: "test_link"})
      end

      it "not return suites without suites_tabs" do
        expect(subject.length).to eq(2)
        expect(subject).to_not include ({title: "Hats - inactive", url: "test_link"})
      end
    end
  end

  context "invalid keywords" do
    describe ".search" do
      def results_for(keywords)
        described_class.new(keywords, view_context).results
      end

      it "returns empty array if no keyword is given" do
        expect(results_for("")).to eq []
      end

      it "returns empty array if no only spaces is given" do
        expect(results_for(" ")).to eq []
      end
    end
  end

end
