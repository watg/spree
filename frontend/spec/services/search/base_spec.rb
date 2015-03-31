require "spec_helper"

module Search
  describe Base do
    context "correct filters" do
      let!(:suite1) { create(:suite, :with_tab, title: "RoR Mug") }
      let!(:suite2) { create(:suite, :with_tab, title: "RoR Shirt") }
      let!(:taxon) { create(:taxon, name: "Ruby on Rails") }

      before do
        suite1.taxons << taxon
        suite2.taxons << taxon
      end

      it "returns all suites with tabs by default" do
        create(:suite, title: "RoR Shirt2")
        params = {}

        searcher = described_class.new(params)
        expect(searcher.results.count(:all)).to eq(2)
      end

      it "switches to next page according to the page parameter" do
        create(:suite, :with_tab, title: "RoR Pants")

        params = { per_page: "2" }
        searcher = described_class.new(params)
        expect(searcher.results.count(:all)).to eq(2)

        params.merge! page: "2"
        searcher = described_class.new(params)
        expect(searcher.results.count(:all)).to eq(1)
      end

      it "returns suites matching the keywords using AND logic" do
        IndexedSearch.rebuild
        params = { keywords: "ror mug" }
        searcher = described_class.new(params)
        expect(searcher.results.count(:all)).to eq(1)
      end

      it "returns suites within taxons matching the keywords" do
        suite2.taxons.clear
        IndexedSearch.rebuild
        params = { keywords: "Rails" }
        searcher = described_class.new(params)
        expect(searcher.results.count(:all)).to eq(1)
      end

      it "returns suites with keywords matching both suite and taxons" do
        IndexedSearch.rebuild
        params = { keywords: "ruby shirt" }
        searcher = described_class.new(params)
        expect(searcher.results.count(:all)).to eq(1)
      end
    end
    context "#num_pages" do
      it "returns the total pages" do
        params = { keywords: "" }
        searcher = described_class.new(params)
        allow(searcher).to receive(:results).and_return([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        searcher.instance_variable_set("@per_page", 10)
        expect(searcher.num_pages).to eq(1)
        searcher.instance_variable_set("@per_page", 5)
        expect(searcher.num_pages).to eq(2)
        searcher.instance_variable_set("@per_page", 1)
        expect(searcher.num_pages).to eq(10)
      end
    end
  end
end
