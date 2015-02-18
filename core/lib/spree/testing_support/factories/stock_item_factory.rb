FactoryGirl.define do
  factory :stock_item, class: Spree::StockItem do
    variant
    stock_location
    supplier
    backorderable false

    transient do
      count_on_hand nil
    end

    after(:build) do |object, evaluator|
      if evaluator.count_on_hand
        object.set_count_on_hand( evaluator.count_on_hand )
      end
    end

    after(:create) { |object| object.adjust_count_on_hand(10) }

  end
end
