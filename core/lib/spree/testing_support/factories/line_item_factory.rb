FactoryGirl.define do
  factory :base_line_item, class: Spree::LineItem do
    quantity 1
    price { BigDecimal.new("10.00") }
    pre_tax_amount { price }
    currency "USD"

    before(:create) do |_object, _e|
      Spree::LineItem.skip_callback(:save, :after, :update_inventory)
      Spree::LineItem.skip_callback(:save, :after, :update_adjustments)
    end

    after(:create) do |_object, _e|
      Spree::LineItem.set_callback(:save, :after, :update_inventory)
      Spree::LineItem.set_callback(:save, :after, :update_adjustments)
    end
  end

  factory :line_item, class: Spree::LineItem do
    quantity 1
    price { BigDecimal.new("10.00") }
    pre_tax_amount { price }
    currency "USD"
    order
    transient do
      association :product
    end
    variant{ product.master }
    after(:build) do |object, _e|
      object.item_uuid = Spree::VariantUuid.fetch(object.variant, nil, nil).number
    end
  end
end
