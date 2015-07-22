require "spec_helper"

module Search
  describe Base do
    context "correct filters" do
      let!(:product){ create(:product, description: "test") }
      let!(:suite1) { create(:suite, title: "RoR Mug") }
      let!(:suite2) { create(:suite, title: "RoR Shirt") }
      let!(:taxon) { create(:taxon, name: "Ruby on Rails") }
      let!(:suite_tab1) { create(:suite_tab, suite: suite1, product: product) }
      let!(:suite_tab2) { create(:suite_tab, suite: suite2, product: product) }

      before do
        suite1.taxons << taxon
        suite2.taxons << taxon
      end

      it "returns all suites with tabs by default" do
        create(:suite, title: "RoR Shirt2")
        params = {}

        searcher = described_class.new(params)
        expect(searcher.results.length).to eq(2)
      end

      it "loads the first page if the request page does not contain any suites" do
        create(:suite, title: "RoR Shirt2")
        params = {}

        searcher = described_class.new(params)
        searcher.instance_variable_set("@per_page", 10)
        searcher.instance_variable_set("@page", 2)
        expect(searcher.results.size).to eq 2
      end

      context "non indexable suites" do
        before do
          suite1.indexable = false
          suite1.save
        end

        it "does not return suite that are not indexable" do
          params = {}
          searcher = described_class.new(params)
          expect(searcher.results.length).to eq(1)
          expect(searcher.results).to_not include(suite1)
        end
      end

      it "switches to next page according to the page parameter" do
        create(:suite, :with_tab, title: "RoR Pants")

        params = { per_page: "2" }
        searcher = described_class.new(params)
        expect(searcher.results.length).to eq(2)

        params.merge! page: "2"
        searcher = described_class.new(params)
        expect(searcher.results.length).to eq(1)
      end

      it "returns suites matching the keywords using AND logic" do
        IndexedSearch.rebuild
        params = { keywords: "ror mug" }
        searcher = described_class.new(params)
        expect(searcher.results.length).to eq(1)
      end

      it "returns suites within taxons matching the keywords" do
        suite2.taxons.clear
        IndexedSearch.rebuild
        params = { keywords: "Rails" }
        searcher = described_class.new(params)
        expect(searcher.results.length).to eq(1)
      end

      it "returns suites with keywords matching both suite and taxons" do
        IndexedSearch.rebuild
        params = { keywords: "ruby shirt" }
        searcher = described_class.new(params)
        expect(searcher.results.length).to eq(1)
      end

      context "searching by product description" do
        it "returns suites with product description that matches the search" do
          IndexedSearch.rebuild
          params = { keywords: "test" }
          searcher = described_class.new(params)
          expect(searcher.results.length).to eq(2)
        end
      end

      context "with taxons and suites that matches search" do
        let!(:suite3) { create(:suite, :with_tab, title: "Ruby on Rails") }
        before do
          suite3.taxons << taxon
          suite3.suite_tabs.first.update(product: product)

        end

        it "returns suites with searched name hover taxon name" do
          IndexedSearch.rebuild
          params = { keywords: "Ruby on Rails" }
          searcher = described_class.new(params)
          expect(searcher.results.first).to eq(suite3)
        end
      end

      it "returns the total pages" do
        create(:suite, :with_tab, title: "RoR Pants")
        searcher1 = described_class.new(per_page: 3)
        expect(searcher1.num_pages).to eq(1)

        searcher2 = described_class.new(per_page: 2)
        expect(searcher2.num_pages).to eq(2)

        searcher3 = described_class.new(per_page: 1)
        expect(searcher3.num_pages).to eq(3)
      end
    end
  end
end
