require 'spec_helper'

describe "setting locale" , :type => :featuredo
  before do
    pending "to fix"
    I18n.locale = I18n.default_locale
    Spree::Frontend::Config[:locale] = 'en'
  end

  after do
    I18n.locale = I18n.default_locale
    Spree::Frontend::Config[:locale] = "en"
  end

  it "should be in french" do
    visit spree.root_path
    click_link "Panier"
    page.should have_content("Panier")
  end
end
