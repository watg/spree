FactoryGirl.define do
  factory :order_type, aliases: [:regular_order_type], class: Spree::OrderType do
    name "regular"
    title "Regular"
    default true
  end

  factory :party_order_type, class: Spree::OrderType do
    name "party"
    title "Party"
    default false
  end
end
