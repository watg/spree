FactoryGirl.define do
  factory :shipping_rate, class: Spree::ShippingRate do
  end

  factory :selected_shipping_rate, class: Spree::ShippingRate do
    selected true
  end
end
