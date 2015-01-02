FactoryGirl.define do
  # must use build()
  factory :stock_packer, class: Spree::Stock::Packer do
    transient do
      stock_location { build(:stock_location) }
      contents []
    end

    initialize_with { new(stock_location, contents) }
  end

  factory :stock_package, class: Spree::Stock::Package do
    transient do
      stock_location { build(:stock_location) }
      contents       { [] }
      line_items { [] }
    end

    initialize_with { new(stock_location, contents) }
    
    after(:build) do |package, evaluator|
      evaluator.line_items.each do |line_item|
        package.add_multiple build_list(:inventory_unit, line_item.quantity, line_item: line_item, variant: line_item.variant)
      end
    end

    factory :stock_package_fulfilled do
      ignore do 
        variant { build(:variant) }
        line_item { build(:line_item, quantity: 2, variant: variant) }
        line_items { [line_item] }
      end
    end
  end
end
