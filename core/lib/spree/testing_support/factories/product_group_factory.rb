FactoryGirl.define do
  factory :product_group, class: Spree::ProductGroup do
    sequence(:name) {|n| "Tala Tank #{n}" }
  end
end
