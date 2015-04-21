FactoryGirl.define do
  factory :marketing_type, class: Spree::MarketingType do
    name "gang"

    trait :pattern do
      id 6
      name "pattern"
    end

    trait :embellishment do
      id 7
      name "embellishment"
    end
  end
end
