require "feature_helper"

feature "buying multi option product" do
  let!(:hat)      { create(:product, :with_marketing_type, sku: "ready", name: "bag", slug: "bag") }

  let!(:suite)    { create(:suite, name: " Bag ", title: "bag", permalink: "bag") }
  let!(:tab)      { create(:suite_tab, tab_type: "made-by-the-gang", suite: suite, product: hat) }

  let!(:option)   { create(:option_type, name: "colour") }
  let(:colours)   { %w|blue red| }
  let!(:values)   { create_option_values }
  let(:variants)  { create_variants }

  let(:strap)     { create(:product, name: "strap") }
  let(:red)       { values[0] }
  let(:red_strap) { create(:variant, product: strap, option_values: [red], in_stock_cache: true) }
  let(:price)     { create(:price, price_type: "part") }
  let(:prod_part) { create(:product_part, product: hat, part: strap, displayable_option_type: option) }
  let(:ppv)       { create(:product_part_variant, variant: red_strap, product_part: prod_part) }

  let(:hat_page)  { spree.suite_path(id: suite.permalink, tab: tab.tab_type) }

  before do
    red_strap.prices = [price]
    prod_part.product_part_variants = [ppv]

    variants.each do |v|
      v.stock_items.first.set_count_on_hand(1)
      v.stock_items.first.update_column(:backorderable, false)
    end
  end

  scenario "user selects preferred color and part", js: true do
    visit hat_page
    verify_chosen_colour("blue")
    verify_product_price("$19.99")

    choose_blue_part
    verify_product_price("$29.98")

    choose_red_hat
    verify_chosen_colour("red")
    verify_product_price("$29.98")

    checkout

    verify_chosen_product_in_cart
  end

  def create_option_values
    colours.map{ |c| create(:option_value, option_type: option, name: c, presentation: c) }
  end

  def create_variants
    values.map{ |v| create(:base_variant, product: hat, option_values: [v], in_stock_cache: true) }
  end

  def verify_chosen_colour(colour)
    expect(find(".color-value").text).to eq colour.upcase
  end

  def verify_product_price(price)
    expect(find(".normal-price").text).to eq price
  end

  def choose_blue_part
    find(".optional").click
    page.find(".row-assembly a.option-value.blue.colour span").click
  end

  def choose_red_hat
    click_link("red")
  end

  def checkout
    click_button("Add To My Bag")
    click_link("Checkout")
  end

  def verify_chosen_product_in_cart
    expect(current_path).to eq "/cart"
    expect(page).to have_content("Color: red")
    expect(page).to have_content("strap -- Color: blue")
  end
end
