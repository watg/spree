require "feature_helper"

describe "setting locale", type: :feature do
  before do
    pending "to fix"
    I18n.locale = I18n.default_locale
    Spree::Frontend::Config[:locale] = "en"
  end

  after do
    I18n.locale = I18n.default_locale
    Spree::Frontend::Config[:locale] = "en"
  end

  it "is in french" do
    visit spree.root_path
    click_link "Panier"
    expect(page).to have_content("Panier")
  end
end
