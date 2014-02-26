FactoryGirl.define do
  factory :product_page_variant, class: Spree::ProductPageVariant do
    product_page
    variant
  end
end
