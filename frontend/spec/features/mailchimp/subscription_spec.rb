require "feature_helper"

describe "Newsletter subscription", inaccessible: true do

  context "on homepage" do
    it "should be successful" do
      pending "Enable once the competition subscription is over"
      visit spree.root_path
      fill_in "signupEmail", :with => "email@person.com"
      click_button "I'm in!"
      expect(page).to have_content("Wool respect")

      expect(Spree::User.where(email: 'email@person.com', enrolled: false, subscribed: true)).to exist
    end
  end

  context "on footer on any page" do
    let!(:marketing_type) { create(:marketing_type) }
    let!(:product) { create(:product, marketing_type: marketing_type) }
    let!(:suite) { create(:suite, permalink: "martin") }
    let!(:tab) { create(:suite_tab, suite: suite, product: product, tab_type: 'knit-your-own') }

    it "should be successful" do
      visit spree.suite_path(id: suite.permalink, tab: tab.tab_type)
      within '.newsletter-subscribe' do
        fill_in "signupEmail", :with => "email@person.com"
        click_button "Submit"
      end
      expect(page).to have_content("Wool respect")

      expect(Spree::User.where(email: 'email@person.com', enrolled: false, subscribed: true)).to exist
    end
  end

end
