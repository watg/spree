require "feature_helper"

feature 'buying ready to wear products' do
  let!(:hat)     { create(:product, :with_marketing_type, sku: 'ready', name: 'bag', slug: 'bag') }

  let!(:suite)   { create(:suite, name: ' Bag ', title: 'bag', permalink: 'bag') }
  let!(:tab)     { create(:suite_tab, tab_type: "made-by-the-gang", suite: suite, product: hat) }

  let!(:colour)  { create(:option_type, name: 'colour') }
  let(:colours)  { %w|blue red green| }
  let!(:options) { create_option_values }
  let(:variants) { create_variants }

  before do
    variants.each do |v|
      v.stock_items.first.set_count_on_hand(1)
      v.stock_items.first.update_column(:backorderable, false)
    end
  end

  scenario 'user selects favourite color', js: true do
    visit spree.suite_path(id: suite.permalink, tab: tab.tab_type)
    expect(page).to have_content 'BAG'

    page.find("a.green").click
    expect(page).to have_content('green')

    find_button('Add To My Bag').click
    expect(page).to have_content('ADDED TO YOUR CART')
    expect(page).to have_content('BAG')

    click_link("Checkout")
    expect(page).to have_content('Color: green')
    expect(current_path).to eq "/cart"
  end

  def create_option_values
    colours.map{ |c| create(:option_value, option_type: colour, name: c, presentation: c) }
  end

  def create_variants
    options.map{ |o| create(:base_variant, product: hat, option_values: [o], in_stock_cache: true) }
  end
end
