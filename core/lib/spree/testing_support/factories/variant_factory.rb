FactoryGirl.define do
  sequence(:random_float) { BigDecimal.new("#{rand(200)}.#{rand(99)}") }

  factory :base_variant, class: Spree::Variant do
		cost_price 10

    ignore do
      target nil
      amount nil
      currency 'USD'
    end

    after(:build) do |i,evaluator|
      if evaluator.amount
        i.price_normal_in(evaluator.currency).amount = evaluator.amount
      end
    end

    after :create do |i,evaluator|
      if evaluator.target
        create(:variant_target, variant: i, target: evaluator.target)
      end
    end

    # upgraded
    # cost_price 17.00
    sku    { SecureRandom.hex }
    weight 10
    height { generate(:random_float) }
    width  { generate(:random_float) }
    depth  { generate(:random_float) }
    is_master 0
    track_inventory true

    product { |p| p.association(:base_product) }
    option_values { [create(:option_value)] }
    sequence(:permalink)  {|n| "knit1221ter-1-00#{n}"}

    # ensure stock item will be created for this variant
    before(:create) { create(:stock_location) if Spree::StockLocation.count == 0 }
    
    factory :variant do
      # on_hand 5
      in_stock_cache false
      product { |p| p.association(:product) }

      factory :variant_in_sale do
        in_sale true

        ignore do
          amount 19.99
          sale_amount 6
        end

        after(:build) do |i,evaluator|
          i.price_normal_sale_in(evaluator.currency).amount = evaluator.sale_amount
        end

      end

      factory :variant_with_stock_items do
        in_stock_cache true
        after :create do |object, evaluator| 
          object.stock_items.each { |si| si.adjust_count_on_hand(10) }
        end
      end
    end

    factory :master_variant do
      is_master 1
    end

    factory :on_demand_variant do
      track_inventory false

      factory :on_demand_master_variant do
        is_master 1
      end
    end

  end
end
