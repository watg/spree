require 'spec_helper'

describe "Sign Up" do
  context "with valid data" do
    it "should create a new user" do
      visit spree.signup_path
      fill_in "Email", :with => "email@person.com"
      fill_in "Password", :with => "password"
      fill_in "Password Confirmation", :with => "password"
      click_button "Create"
      expect(page).to have_content("You have signed up successfully.")
      expect(Spree::User.where(email: 'email@person.com', enrolled: true, subscribed: nil)).to exist
    end
  end
  
  context "with subscribed checked" do
    it "should create a new user" do
      visit spree.signup_path
      fill_in "Email", :with => "email@person.com"
      fill_in "Password", :with => "password"
      fill_in "Password Confirmation", :with => "password"
      check "spree_user_subscribed"
      click_button "Create"
      expect(page).to have_content("You have signed up successfully.")
      expect(Spree::User.where(email: 'email@person.com', enrolled: true, subscribed: true)).to exist
    end
  end

  context "for an unenrolled user" do
    before do
      create(:user, :email => "email@person.com", :enrolled => false)
    end

    it "should create a new user" do
      visit spree.signup_path
      fill_in "Email", :with => "email@person.com"
      fill_in "Password", :with => "password"
      fill_in "Password Confirmation", :with => "password"
      click_button "Create"
      expect(page).to have_content("You have signed up successfully.")
      expect(Spree::User.where(email: 'email@person.com', enrolled: true)).to exist
    end
  end

  context "with invalid data" do
    it "should not create a new user" do
      visit spree.signup_path
      fill_in "Email", :with => "email@person.com"
      fill_in "Password", :with => "password"
      fill_in "Password Confirmation", :with => ""
      click_button "Create"
      expect(page).to have_css("#errorExplanation")
      expect(Spree::User.where(email: 'email@person.com')).to be_empty
    end
  end
end
