require "feature_helper"

feature "buying multi option product" do
  let!(:hat)     { create(:product, :with_marketing_type, sku: "ready", name: "bag", slug: "bag") }

  let!(:suite)   { create(:suite, name: " Bag ", title: "bag", permalink: "bag") }
  let!(:tab)     { create(:suite_tab, tab_type: "made-by-the-gang", suite: suite, product: hat) }

  let!(:size)    { create(:option_type, name: "size", position: '1') }
  let(:sizes)    { %w|small medium large| }
  let(:s_opts)   { create_option_values(size, sizes) }

  let!(:colour)  { create(:option_type, name: "colour", position: '2') }
  let(:colours)  { %w|blue red green| }
  let!(:c_opts)  { create_option_values(colour, colours) }

  let(:variants) { create_variants }
  let(:red_med)  { variants[4] }
  let(:hat_page) { spree.suite_path(id: suite.permalink, tab: tab.tab_type) }

  before do
    variants.each do |v|
      v.stock_items.first.set_count_on_hand(1)
      v.stock_items.first.update_column(:backorderable, false)
    end

    red_med.update_column(:in_stock_cache, false)
  end

  scenario "user selects preferred color and size", js: true do
    visit hat_page
    click_link('medium')

    verify_red_medium_variant_unavailable
    expect(find('span.colour').text).to be_empty
    expect(find('.add-to-cart-button')[:disabled]).to be_truthy

    click_link('blue')

    expect(find('span.colour').text).to eq 'BLUE'

    checkout

    expect(current_path).to eq "/cart"
    expect(page).to have_content("Color: blue")
  end

  def create_option_values(option_type, options)
    options.map{ |o| create(:option_value, option_type: option_type, name: o, presentation: o) }
  end

  def create_variants
    combos.map{ |p| create(:base_variant, product: hat, option_values: p, in_stock_cache: true) }
  end

  def combos
    s_opts.each.inject([]) do |array, s|
      c_opts.map{ |c| array << [s, c] }
      array
    end
  end

  def verify_red_medium_variant_unavailable
    expect(page).to have_css('a.red.locked')
  end

  def checkout
    click_button("Add To My Bag")
    click_link('Checkout')
  end
end
