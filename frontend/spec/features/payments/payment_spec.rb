require "feature_helper"
RSpec.feature "Payment", type: :feature do
  let(:user) do
    Spree.user_class = 'Spree::User'
    create(:user, email: "email@person.com", password: "secret", password_confirmation: "secret")
  end

  let!(:hat_product) do
    create(:product,
           :with_marketing_type,
           sku: "this-is-a-kit",
           name: "Sun Dance Hat",
           slug: "sun-dance-hat-1")
  end
  let!(:hat_variant)  { hat_product.master }

  let!(:suite) do
    create(:suite, name: " Sun Dance Hat ", title: "sun dance hat", permalink: "sundance-hat")
  end

  let!(:suite_tab) do
    create(:suite_tab,
           tab_type: "knit-your-own",
           suite: suite,
           product: hat_product,
           in_stock_cache: true)
  end

  let!(:shipping_method) { create(:shipping_method) }
  # create option type with two option values
  let!(:colour) { create(:option_type, name: "colour", position: 2) }
  let!(:blue) do
    create(:option_value, option_type: colour, name: "blue", presentation: "blue", position: 2)
  end

  let!(:red) do
    create(:option_value, option_type: colour, name: "red", presentation: "red", position: 2)
  end

  let!(:colour_variant_one) do
    create(:base_variant, product: hat_product, option_values: [blue], in_stock_cache: true)
  end

  let!(:colour_variant_two) do
    create(:base_variant, product: hat_product, option_values: [red], in_stock_cache: true)
  end

  let!(:credit_card_payment_method) { create(:adyen_payment_method, environment: :features) }
  let!(:paypal_test_payment_method) { create(:paypal_test_payment_method, environment: :features) }

  before do
    kill_popups
    login(user)
    colour_variant_one.stock_items.first.set_count_on_hand(1)
    colour_variant_one.stock_items.first.update_column(:backorderable, false)
    colour_variant_two.stock_items.first.set_count_on_hand(1)
    colour_variant_two.stock_items.first.update_column(:backorderable, false)
  end

  scenario "pays with card(adyen)", js: true do
    buy_and_checkout
    choose("Adyen Test Gateway")
    find("input[data-encrypted-name='holderName']").set("Oliver Queen")
    find("input[data-encrypted-name='number']").set("5555444433331111")
    find("input[data-encrypted-name='expiryMonth']").set("06")
    find("input[data-encrypted-name='expiryYear']").set("2016")
    find("input[data-encrypted-name='cvc']").set("737")
    # If it calls this method it means that the javascript is loaded
    expect_any_instance_of(Spree::Gateway::AdyenPaymentEncrypted)
      .to receive(:authorize_on_card)
      .and_call_original
    click_button("Place Order")
  end

  scenario "pays with paypal", js: true do
    buy_and_checkout
    find(".PayPal input").trigger("click")
    expect(page).to have_selector(:link_or_button, "paypal_button")
  end

  def buy_and_checkout
    visit spree.suite_path(id: suite.permalink, tab: suite_tab.tab_type)
    find_button("Add To My Bag").click
    sleep(1)
    click_link("Checkout")
    click_button("Checkout")
    fill_adress_form
    click_button("Save and Continue")
    click_button("Save and Continue")
  end

  def fill_adress_form
    fill_in "First Name",    with: "John"
    fill_in "Last Name",     with: "Diggle"
    fill_in "Street Address", with: "Oliv Base"
    fill_in "City",          with: "Central City"
    select "United States of America", from: "Country"

    select "Alabama", from: "order[bill_address_attributes][state_id]"
    fill_in "Zip/Post Code", with: "36006"
    fill_in "Phone",         with: "2053486010"
  end

  def login(user)
    visit spree.login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Login"
  end
end
