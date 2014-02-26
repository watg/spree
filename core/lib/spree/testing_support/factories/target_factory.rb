FactoryGirl.define do
  factory :target, class: Spree::Target do
    sequence(:name) { |n| "Target ##{n}" }
  end
end
