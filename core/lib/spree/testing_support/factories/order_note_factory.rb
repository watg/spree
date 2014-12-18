FactoryGirl.define do
  factory :order_note, class: Spree::OrderNote do
    user
    order
    reason "some reason"
  end
end
