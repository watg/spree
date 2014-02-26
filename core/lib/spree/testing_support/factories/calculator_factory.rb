FactoryGirl.define do
  factory :calculator, class: Spree::Calculator::FlatRate do
    after(:create) { |c| c.preffered_amount = [{value: 10.0, name: 'USD' }] }
  end

  factory :no_amount_calculator, class: Spree::Calculator::FlatRate do
    after(:create) { |c| c.preffered_amount = [{value: 0.0, name: 'USD' }] }
  end

  factory :default_tax_calculator, class: Spree::Calculator::DefaultTax do
  end
end
