FactoryGirl.define do
  factory :suite_tab, class: Spree::SuiteTab do
    sequence(:tab_type)  {|n| "tab_type-#{n}"}
    suite                { build_stubbed(:suite) }
    product              { build_stubbed(:product) }
    in_stock_cache       true
  end
end
