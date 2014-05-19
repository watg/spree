FactoryGirl.define do
  factory :product_type, class: Spree::ProductType do
    name 'normal'
    is_digital false
    is_internal false
    is_promotable true

    factory :product_type_kit do
      name 'kit'
    end

    factory :product_type_gift_card do
      name 'gift_card'
      is_digital true
      is_promotable false
    end

    factory :product_type_packaging do
      name 'packaging'
      is_internal true
      is_promotable false
    end

  end
end
