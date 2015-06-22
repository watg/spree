require "feature_helper"

feature "searching" do
  let(:taxon) { create(:taxon, name: "Taxon Name") }

  let(:suite1) { create(:suite, :with_tab, title: "Sun Dance Hat") }
  let(:suite2) { create(:suite, :with_tab, title: "Sun Dance Scarf") }
  let(:suite3) { create(:suite, :with_tab, title: "Other Suite") }
  let(:product) { create(:product) }
  let(:no_results_text) { "No results found" }

  before do
    suite1.taxons << taxon
    suite2.taxons << taxon
    suite3.taxons << create(:taxon)
    suite1.suite_tabs.first.update(product: product)
    suite2.suite_tabs.first.update(product: product)
    suite3.suite_tabs.first.update(product: product)

    IndexedSearch.rebuild
  end

  before do
    visit root_path
  end

  context "when no results are found" do
    it "displays a friendly no results message" do
      search_for("Non-existing suite title")

      expect(page).to have_content(no_results_text)
      expect(page).not_to have_content(suite1.title)
    end
  end

  context "by suite title" do
    it "shows matching suites" do
      search_for("sun")
      expect(page).to have_content("Search results")
      expect(page).not_to have_content(no_results_text)

      expect(page).to have_content(suite1.title)
      expect(page).to have_content(suite2.title)
      expect(page).not_to have_content(suite3.title)
    end
  end

  context "by taxon name" do
    it "shows matching suites" do
      search_for("taxon")
      expect(page).not_to have_content(no_results_text)

      expect(page).to have_content(suite1.title)
      expect(page).to have_content(suite2.title)
      expect(page).not_to have_content(suite3.title)
    end
  end
end

def search_for(input)
  fill_in "search-input", with: input
  click_button "Search"
end
