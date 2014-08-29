FactoryGirl.define do
  factory :stock_item, class: Spree::StockItem do
    variant
    stock_location
    supplier
    backorderable false

    after(:create) { |object| object.adjust_count_on_hand(10) }
  end
end
