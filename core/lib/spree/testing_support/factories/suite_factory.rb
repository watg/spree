FactoryGirl.define do
  factory :suite, class: Spree::Suite do
    sequence(:name) {|n| "Suite ##{n}" }
    sequence(:title) {|n| "Suite title ##{n}" }
    sequence(:permalink)  {|n| "suite-permalink-#{n}"}
  end
end
