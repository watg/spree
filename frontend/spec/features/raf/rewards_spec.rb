require 'spec_helper'

describe "Rewards", inaccessible: true do

  context "when coming as a guest" do
    it "should deny access when not logged in and redirect to login page" do
      visit spree.raf_rewards_path
      expect(page).to have_content('link to the homepage')
    end
  end

  context "when registered" do
    let!(:user) { create(:user) }

    before(:each) do
      visit spree.login_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Login'
    end

    it "should redirect if the user does not have a profile" do
      visit spree.raf_rewards_path
      expect(current_path).to eq spree.raf_invite_path
    end

    context "collecting the rewards" do
      let!(:referrer) { Spree::Raf::Referrer.create!(user: user, currency: 'USD') }
      let!(:reward) { Spree::Raf::Reward.create!(referrer: referrer, state: :approved, amount: 5) }

      before do
        allow_any_instance_of(Spree::Raf::Referrer).to receive(:can_collect?).and_return(true)
        allow_any_instance_of(Spree::Raf::RewardReferrerService).to receive(:run).with(referrer: referrer)
      end

      it "collects the reward" do
        visit spree.raf_rewards_path
        
        click_link 'Redeem your rewards'
        expect(page).to have_content "Yay! You've just redeemed your earnings"
      end
    end
  end

end
