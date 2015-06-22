require "spec_helper"

RSpec.feature "Prices", type: :feature do
  let!(:user)        { create(:user) }
  let!(:variant)     { create(:variant) }
  let(:master)       { variant.product.master }

  let!(:variant_gbp) { create(:price, defaults.merge(currency: "GBP")) }
  let!(:variant_eur) { create(:price, defaults.merge(currency: "EUR")) }
  let!(:variant_usd) { create(:price, defaults.merge(currency: "USD")) }

  let!(:master_gbp)  { create(:price, defaults.merge(currency: "GBP")) }
  let!(:master_eur)  { create(:price, defaults.merge(currency: "EUR")) }
  let!(:master_usd)  { create(:price, defaults.merge(currency: "USD")) }

  let(:defaults)     { { amount: 10, sale_amount: 20, part_amount: 30 } }
  let(:admin_ui)     { Support::AdminUi.new(user: user, variant: variant, master: master) }

  background do
    user.spree_roles << Spree::Role.find_or_create_by(name: 'admin')
    variant.prices = [variant_gbp, variant_usd, variant_eur]
    master.prices  = [master_gbp, master_usd, master_eur]
  end

  scenario do
    admin_ui.login
    admin_ui.visit_item
    admin_ui.check_price_form(variant.product.master.id)
    admin_ui.check_price_form(variant.id)
    admin_ui.update_item
    admin_ui.confirm_item_updated
  end
end