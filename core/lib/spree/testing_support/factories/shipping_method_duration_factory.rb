FactoryGirl.define do
  factory :shipping_method_duration, class: Spree::ShippingMethodDuration do
    description 'in 4 to 10 days'
    min 2
    max 3
  end
end
