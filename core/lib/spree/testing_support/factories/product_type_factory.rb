FactoryGirl.define do
  factory :product_type, class: Spree::ProductType do
    name 'normal'
    is_digital false
    is_operational false
    is_promotable true
    is_assembly false

    factory :product_type_kit do
      name 'kit'
      is_assembly true
    end

    factory :product_type_gift_card do
      name 'gift_card'
      is_digital true
      is_promotable false
    end

    factory :product_type_packaging do
      name 'packaging'
      is_operational true
      is_promotable false
    end

    trait :kit do
      name 'kit'
    end
  end
end
