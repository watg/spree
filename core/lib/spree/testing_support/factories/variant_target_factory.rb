FactoryGirl.define do
  factory :variant_target, class: Spree::VariantTarget do
    variant
    target
  end
end
