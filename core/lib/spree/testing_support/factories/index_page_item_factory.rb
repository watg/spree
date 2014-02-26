FactoryGirl.define do
  factory :index_page_item, class: Spree::IndexPageItem do
    index_page
    title "Index page item"
    product_page
  end
end
