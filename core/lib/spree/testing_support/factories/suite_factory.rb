FactoryGirl.define do
  factory :suite, class: Spree::Suite do
    sequence(:name) {|n| "Suite ##{n}" }
    sequence(:title) {|n| "Suite title ##{n}" }
    sequence(:permalink)  {|n| "suite-permalink-#{n}"}

    trait :with_tab do
      after :create do |suite, evaluator|
        create(:suite_tab, suite: suite)
      end
    end
  end
end
