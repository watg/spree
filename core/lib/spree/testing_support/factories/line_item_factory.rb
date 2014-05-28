FactoryGirl.define do
  factory :line_item, class: Spree::LineItem do
    quantity 1
    price { BigDecimal.new('10.00') }
    order
    currency 'USD'
    variant
    product_page
    product_page_tab
  end
end
