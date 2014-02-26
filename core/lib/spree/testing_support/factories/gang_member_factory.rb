FactoryGirl.define do
  factory :gang_member, class: Spree::GangMember do
    sequence(:firstname) {|n| "Queen Knitter #{n}"}
    sequence(:lastname)  {|n| "WATG #{n}"}
    sequence(:permalink)  {|n| "knitter-#{n}"}
    profile   { Faker::Lorem.paragraph }
    visible false
  end
end