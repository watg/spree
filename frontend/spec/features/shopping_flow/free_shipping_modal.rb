require "spec_helper"

feature "when visiting a page" do
  let!(:zone) do
    Spree::Zone.where(name: "GlobalZone").first || create(:global_zone)
  end
  let!(:promotion) do
    create(
      :promotion,
      id: Spree::Promotable::GlobalFreeShipping::GLOBAL_FREE_SHIPPING_PROMOTION_ID
    )
  end
  let!(:rule) do
    Spree::Promotion::Rules::ItemTotal.create!(
      promotion: promotion, preferred_attributes: preferred_attributes
  )
  end
  let!(:preferred_attributes) do
    { zone.id.to_s => { "USD" => { "amount" => "100", "enabled" => "true" } } }
  end
  let!(:country) do
    Spree::Country.create(
      name: "US", iso_name: "US", iso: "US", states_required: false
    )
  end

  before do
    zone.zone_members.create(zoneable: country)
  end

  scenario "free shipping modal is available" do
    visit spree.root_path
    expect(page).to have_content("Free shipping")
    expect(page).to have_content("on orders over $100.00")
  end

  feature "and zone does not have free shipping" do
    before do
      rule.preferred_attributes = {}
      rule.save
    end

    scenario "free shipping modal is not available" do
      visit spree.root_path
      expect(page).to_not have_content("Free shipping")
    end
  end
end
