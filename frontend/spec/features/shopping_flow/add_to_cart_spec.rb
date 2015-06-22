require 'spec_helper'


feature 'adding product to cart', inaccessible: true do

  let!(:hat_product)  { create(:product, :with_marketing_type, sku: 'this-is-a-kit', name: 'Sun Dance Hat', slug: 'sun-dance-hat-1') }
  let!(:hat_variant)  { hat_product.master }

  let!(:suite) { create(:suite, name: ' Sun Dance Hat ', title: 'sun dance hat', permalink: 'sundance-hat') }
  let!(:suite_tab) { create(:suite_tab, tab_type: "knit-your-own", suite: suite, product: hat_product, in_stock_cache: true) }

  # create option type with two option values
  let!(:colour) { create(:option_type, name: 'colour', position: 2 )}
  let!(:blue) { create(:option_value, option_type: colour, name: 'blue', presentation: 'blue', position: 2 )}
  let!(:red) { create(:option_value, option_type: colour, name: 'red', presentation: 'red', position: 2 )}

  let!(:colour_variant_one) { create(:base_variant, product: hat_product, option_values: [blue], in_stock_cache: true) }
  let!(:colour_variant_two) { create(:base_variant, product: hat_product, option_values: [red], in_stock_cache: true) }

  before do
    colour_variant_one.stock_items.first.set_count_on_hand(1)
    colour_variant_one.stock_items.first.update_column(:backorderable, false)
    colour_variant_two.stock_items.first.set_count_on_hand(1)
    colour_variant_two.stock_items.first.update_column(:backorderable, false)
    kill_popups
    # Capybara.current_driver = :selenium_chrome
  end


  feature 'when product is an assembly definition' do

    # creates some colour variants for the hat
    let!(:part) { create(:base_product, sku: 'some-wool', name: 'wool') }
    let!(:colour_variant_one) { create(:base_variant, product: part, option_values: [blue], in_stock_cache: true) }
    let!(:colour_variant_two) { create(:base_variant, product: part, option_values: [red], in_stock_cache: true) }

    # creates an assembly definition for the hat
    let!(:assembly_definition) { create(:assembly_definition, variant: hat_variant) }
    let!(:assembly_definition_part) { create(:assembly_definition_part, assembly_definition: assembly_definition, product: part, displayable_option_type: colour ) }

    # links the colour variants to the hat through assemble definition
    let!(:assembly_definition_variant) { create(:assembly_definition_variant, variant: colour_variant_one, assembly_definition_part: assembly_definition_part, assembly_product: part) }
    let!(:assembly_definition_variant_two) { create(:assembly_definition_variant, variant: colour_variant_two, assembly_definition_part: assembly_definition_part, assembly_product: part) }

    scenario 'user selects variant and add to cart', js: true do

      # visit page
      visit spree.suite_path(id: suite.permalink, tab: suite_tab.tab_type)
      expect(page).to have_content 'SUN DANCE HAT'
      expect(current_path).to eq "/product/sundance-hat/knit-your-own"
      expect(page).to have_css('li.product-variants')

      # select a variant
      find(".product-variants").click
      expect(page).to have_css('ul.variant-option-values')
      within(:css, "ul.variant-option-values") do
        Capybara.ignore_hidden_elements = false

        expect(page).to have_content 'red'
        expect(page).to have_css('a.option-value.red.colour', text: 'red')
        page.find('a.option-value.red.colour', text: 'red').click
        Capybara.ignore_hidden_elements = true
      end

      # variant red is selected
      expect(page).to have_content('RED')


      # add to cart and check contents
      find_button('Add To My Bag').click

      # Ensure flash message is correct
      expect(page).to have_content('ADDED TO YOUR CART')
      expect(page).to have_content('SUN DANCE HAT')

      # Proceed to checkout
      click_link("Checkout")

      #find_button('Checkout').click

      # wait until page load
      expect(page).to have_content('PARTS:')
      expect(page).to have_content('Color: red')
      expect(current_path).to eq "/cart"

    end


    feature 'and assembly definition has a part that is a static kit', js: true do

      let!(:static_kit_part_for_product) { create(:base_variant, name: 'static kit part product') }
      let!(:static_kit_part_for_variant) { create(:base_variant, name: 'static kit part variant') }

      before do
        colour_variant_one.product.add_part(static_kit_part_for_product,2, false)
        colour_variant_one.add_part(static_kit_part_for_variant,1, false)

        colour_variant_two.product.add_part(static_kit_part_for_product,2, false)
        colour_variant_two.add_part(static_kit_part_for_variant,1, false)
      end

      scenario 'user selects variants and adds to cart', js: true do

        # visit page
        visit spree.suite_path(id: suite.permalink, tab: suite_tab.tab_type)
        expect(page).to have_content 'SUN DANCE HAT'
        expect(current_path).to eq "/product/sundance-hat/knit-your-own"
        expect(page).to have_css('li.product-variants')

        # select a variant
        find(".product-variants").click
        expect(page).to have_css('ul.variant-option-values')
        within(:css, "ul.variant-option-values") do
          Capybara.ignore_hidden_elements = false

          expect(page).to have_content 'blue'
          page.find('a.option-value.blue.colour')
          expect(page).to have_css('a.option-value.blue.colour', visible: false, text: 'blue')
          page.find('a.option-value.blue.colour', text: 'blue').click
          Capybara.ignore_hidden_elements = true
        end
        expect(page).to have_content('BLUE')


        # add to cart and check contents
        find_button('Add To My Bag').click

        # Ensure flash message is correct
        expect(page).to have_content('ADDED TO YOUR CART')
        expect(page).to have_content('SUN DANCE HAT')

        # Proceed to checkout
        click_link("Checkout")

        expect(page).to have_content('PARTS:')
        expect(page).to have_content('Color: blue')
        expect(current_path).to eq("/cart")

        # checks that the order has correct amount of line items
        order = Spree::Order.last
        expect(order.line_items.size).to eq 1
        parts = order.line_items.first.parts
        expect(parts.size).to eq 3

        # checks one of the line items is just a container
        expect(parts[0].container?).to be false
        expect(parts[1].container?).to be false
        expect(parts[2].container?).to be true
    #     # sleep 100
      end
    end
  end

  feature 'when product has a personalisation option' do

    let!(:monogram) { create(:personalisation_monogram, product: hat_product) }

    scenario 'user selects personalise, chooses two letters and adds to cart', js: true do
      # visit page
      visit spree.suite_path(id: suite.permalink, tab: suite_tab.tab_type)
      expect(page).to have_content 'SUN DANCE HAT'

      # select personalise option
      expect(page).to have_content 'PERSONALISE'
      expect(page).to have_css('.personalisation')
      within(:css, ".personalisation") do
        check('Add a monogram')
      end
      expect(page).to have_content('MAX. 2 CHARACTERS')
      fill_in 'products_pp_ids_1_initials', :with => 'HP'

      # add to cart and check contents
      find_button('Add To My Bag').click

      # Ensure flash message is correct
      expect(page).to have_content('ADDED TO YOUR CART')
      expect(page).to have_content('SUN DANCE HAT, COLOR: BLUE')

      # Proceed to checkout
      click_link("Checkout")
      expect(page).to have_content('Monogram')
      expect(page).to have_content('Colour: Red,')
      expect(page).to have_content('Initials: HP')
      expect(current_path).to eq("/cart")

      # sleep 100
    end
  end   # -- feature

  feature 'when we have a normal product' do

    scenario 'user selects more stock than we have', js: true do
      # visit page
      visit spree.suite_path(id: suite.permalink, tab: suite_tab.tab_type)
      expect(page).to have_content 'SUN DANCE HAT'

      # add to cart a quantity we cannot satisfy
      fill_in 'qty', :with => '9999'
      find_button('Add To My Bag').click

      # Ensure flash message is correct
      expect(page).to have_content('Selected quantity')
      expect(page).to have_content('not available')

      # sleep 100
    end
  end   # -- feature

end
