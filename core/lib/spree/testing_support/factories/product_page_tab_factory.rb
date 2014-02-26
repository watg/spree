FactoryGirl.define do
  factory :product_page_tab, class: 'Spree::ProductPageTab' do
    product_page
    tab_type :made_by_the_gang
  end

  factory :product_page_tab_kit, class: 'Spree::ProductPageTab' do
    product_page
    tab_type :kit
  end

end
