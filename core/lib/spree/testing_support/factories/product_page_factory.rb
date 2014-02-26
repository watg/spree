FactoryGirl.define do
  factory :product_page, class: Spree::ProductPage do
    sequence(:name) {|n| "Tala Tank #{n}" }
    sequence(:title) {|n| "Tala Tank title #{n}" }
    target

    sequence(:permalink)  {|n| "product-page-permalink-#{n}"}
    factory :box_group do
      sequence(:name) {|n| "Box #{n}" }
    end
  end
end
