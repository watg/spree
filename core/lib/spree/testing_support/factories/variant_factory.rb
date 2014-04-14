FactoryGirl.define do
  sequence(:random_float) { BigDecimal.new("#{rand(200)}.#{rand(99)}") }

  factory :base_variant, class: Spree::Variant do
		price 19.99
		cost_price 10
		
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

      ignore do
        target nil
      end

      after :create do |i,evaluator|
        # create(:price, variant_id: i.id, :currency => evaluator.currency, :amount => evaluator.price, :sale => evaluator.sale)
        if evaluator.target
          create(:variant_target, variant: i, target: evaluator.target)
        end
      end

      factory :variant_in_sale do
        in_sale true
        
        after :create do |v|
          v.prices << FactoryGirl.create(:price, variant_id: v.id, amount: 6, sale: true)
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
