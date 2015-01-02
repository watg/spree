FactoryGirl.define do
  factory :promotion, class: Spree::Promotion do
    name 'Promo'

    trait :with_line_item_adjustment do
      transient do
        adjustment_rate 10
      end

      after(:create) do |promotion, evaluator|
        calculator = Spree::Calculator::FlatRate.new
        calculator.preferred_amount = [{type: :integer, name: "USD", value: evaluator.adjustment_rate}]
        action = Spree::Promotion::Actions::CreateItemAdjustments.create(:calculator => calculator)
        promotion.actions << action
        promotion.save
      end
    end
    factory :promotion_with_item_adjustment, traits: [:with_line_item_adjustment]

    trait :with_order_adjustment do
      transient do
        order_adjustment_amount 10
      end

      after(:create) do |promotion, evaluator|
        calculator = Spree::Calculator::FlatRate.new
        calculator.preferred_amount = [{type: :integer, name: "USD", value: evaluator.order_adjustment_amount}]
        action = Spree::Promotion::Actions::CreateAdjustment.create!(:calculator => calculator)
        promotion.actions << action
        promotion.save!
      end
    end

    trait :with_item_total_rule do
      transient do
        item_total_threshold_amount 10
      end

      after(:create) do |promotion, evaluator|
        rule = Spree::Promotion::Rules::ItemTotal.create!(
          #preferred_operator: 'gte',
          preferred_attributes: {Spree::Zone.first.id => { 'USD' => { 'amount' => evaluator.item_total_threshold_amount, 'enabled' => 'true' } }}        )
        promotion.rules << rule
        promotion.save!
      end
    end

  end
end
