FactoryGirl.define do
  factory :supplier, class: Spree::Supplier do
    sequence(:firstname) {|n| "Queen Knitter #{n}"}
    sequence(:lastname)  {|n| "WATG #{n}"}
    sequence(:permalink)  {|n| "knitter-#{n}"}
    profile   { Faker::Lorem.paragraph }
    visible false
    mid_code 'abc1234'
    country
  end
end
