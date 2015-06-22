require "feature_helper"

describe "Referee Discount", inaccessible: true do
  let(:token) { 'REF_TOKEN_01' }
  let(:email) { "person1@wool.com" }

  context "without a registered account (guest)", js: true do

    it "should subscribe to newsletter and issue a discount code" do
      visit spree.raf_welcome_path(token: token, source: 'url')

      fill_in "email", :with => email
      # click email me the code!
      find(".button-form").trigger('click')

      expect(page).to have_content('WELCOME TO THE GANG')
      expect(page).not_to have_content('SORRY, IT SEEMS YOU ARE ALREADY A WATG')
    end

    context "and has a complete order", js: true do
      let!(:order) { create(:order, user: nil, email: email, completed_at: Time.now ) }

      it "should not issue a discount code" do
        visit spree.raf_welcome_path(token: token, source: 'url')

        fill_in "email", :with => email
        # click email me the code!
        find(".button-form").trigger('click')

        expect(page).to have_content('THIS OFFER IS ONLY VALID FOR NEWBIES')
        expect(page).not_to have_content('WELCOME TO THE GANG')
      end
    end
  end
end
