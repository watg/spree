FactoryGirl.define do
  sequence :variant_id do |n|
    9999 + n
  end
  factory :price, class: Spree::Price do
    amount 19.99
    sale_amount 1.99
    part_amount 9.99
    currency 'USD'
    is_kit false
    sale false
    variant_id # a real variant with callbacks makes this hard to test.
  end
end
