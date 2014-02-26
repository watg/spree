FactoryGirl.define do
  factory :price, class: Spree::Price do
    variant
    amount 19.99
    currency 'USD'
    is_kit false
    sale false
  end
end
