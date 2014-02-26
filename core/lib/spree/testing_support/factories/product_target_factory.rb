FactoryGirl.define do
  factory :product_target, class: Spree::ProductTarget do
    product { |p| p.association(:base_product) }
    target
    description "Product Target description"
  end
end
