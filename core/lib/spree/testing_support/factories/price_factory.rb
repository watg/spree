FactoryGirl.define do
  factory :price, class: Spree::Price do
    amount 19.99
    sale_amount 9.99
    part_amount 1.99
    currency 'USD'
    is_kit false
    sale false
    variant
  end
end
