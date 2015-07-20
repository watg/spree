require "spec_helper"
describe Api::Search::PredictableSearch do
  let!(:product) { create(:product, description: "hats for everione") }
  let!(:hats_suite_1) { create(:suite, title: "Hats for test", indexable: true) }
  let!(:hats_suite_2) { create(:suite, title: "Hats for me too", indexable: true) }
  let!(:caps_suite) { create(:suite, title: "I prefer caps", indexable: true) }
  let!(:hats_suite_without_tabs) { create(:suite, title: "Hats - inactive") }
  let!(:taxon) { create(:taxon, name: "the hats taxon") }
  let!(:suite_tab1) { create(:suite_tab, suite: hats_suite_1, product: product) }
  let!(:suite_tab2) { create(:suite_tab, suite: hats_suite_2, product: product) }
  let!(:suite_tab3) { create(:suite_tab, suite: caps_suite, product: product) }
  let(:view_context) do
    double(image_path: "image_url", spree: double(suite_url: "test_link"))
  end
  before do
    hats_suite_1.taxons << taxon
    hats_suite_2.taxons << taxon
    caps_suite.taxons << taxon
    hats_suite_without_tabs.taxons << taxon
  end

  def search_response_item(params)
    default_params = { title: "", url: "test_link", image_url: "image_url", target: nil  }
    default_params.merge(params)
  end

  context "with valid keywords" do
    describe ".search" do
      subject { described_class.run!(keywords: "hat", view: view_context) }
      it "returns suites with title that matches the name" do
        expect(subject.length).to eq(2)
        expect(subject).to include (search_response_item(title: "Hats for test"))
        expect(subject).to include (search_response_item(title: "Hats for me too"))
      end

      it "not return suites with title does not match the search" do
        expect(subject.length).to eq(2)
        expect(subject).to_not include (search_response_item(title: "I prefer caps"))
      end

      it "not return suites which do not have tabs" do
        expect(subject.length).to eq(2)
        expect(subject).to_not include (search_response_item(title: "Hats - inactive"))
      end
    end
  end

  context "not indexable" do
    before do
      hats_suite_1.indexable = false
      hats_suite_1.save
    end
    describe ".search" do
      subject { described_class.run!(keywords: "hat", view: view_context) }
      it "returns suites with title that matches the name" do
        expect(subject.length).to eq(1)
        expect(subject).to include (search_response_item(title: "Hats for me too"))
      end
    end
  end

  context "invalid keywords" do
    describe ".search" do
      def results_for(keywords)
        described_class.run!(keywords: keywords, view: view_context)
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
