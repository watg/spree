FactoryGirl.define do
  factory :suite_tab, class: Spree::SuiteTab do
    sequence(:tab_type)  {|n| "tab_type-#{n}"}
    suite { build_stubbed(:suite) }
    product { build_stubbed(:product) }
  end
end
