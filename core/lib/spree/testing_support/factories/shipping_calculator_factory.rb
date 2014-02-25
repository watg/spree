FactoryGirl.define do
  factory :shipping_calculator, class: Spree::Calculator::Shipping::FlatRate do
    after(:create) { |c| c.set_preference(:amount, 10.0) }
  end

  factory :no_amount_shipping_calculator, class: Spree::Calculator::Shipping::FlatRate do
    after(:create) { |c| c.set_preference(:amount, 0) }
  end
end
