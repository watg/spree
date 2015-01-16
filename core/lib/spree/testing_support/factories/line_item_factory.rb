FactoryGirl.define do
  factory :line_item, class: Spree::LineItem do
    quantity 1
    price { BigDecimal.new('10.00') }
    pre_tax_amount { price }
    currency 'USD'
    order
    transient do
      association :product
    end
    variant{ product.master }

    after(:build) do |object,e|
      object.item_uuid = Spree::VariantUuid.fetch(object.variant,nil,nil).number
    end

  end
end
