FactoryGirl.define do
  factory :line_item, class: Spree::LineItem do
    quantity 1
    price { BigDecimal.new('10.00') }
    order
    currency 'USD'
    variant
    product_page
    product_page_tab

    after(:build) do |line_item, e|
      e.order.line_items << line_item unless e.order.line_items.include?(line_item)
    end

  end
end
