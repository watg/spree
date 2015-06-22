require "spec_helper"

feature "visiting a taxon" do
  let(:taxon) { create(:taxon, permalink: "test") }

  let(:suite1) { create(:suite, :with_tab, title: "Sun Dance Hat") }
  let(:suite2) { create(:suite, :with_tab, title: "Sun Dance Scarf") }

  before do
    suite1.taxons << taxon
    suite2.taxons << taxon
  end

  it "shows all suites for the taxon" do
    visit spree.nested_taxons_path(taxon.permalink)

    expect(page).to have_content(suite1.title)
    expect(page).to have_content(suite2.title)
  end
end
