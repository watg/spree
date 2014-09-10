FactoryGirl.define do
  factory :line_item_part, aliases: [:part], class: Spree::LineItemPart do
    quantity 1
    price { BigDecimal.new('4.99') }
    line_item
    variant
    assembled false
    main_part false
    container false
  end
end
