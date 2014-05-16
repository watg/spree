FactoryGirl.define do
  factory :marketing_type, class: Spree::MarketingType do
    sequence(:category)  {|n| "rtw #{n}"}
    name "gang"
  end
end
