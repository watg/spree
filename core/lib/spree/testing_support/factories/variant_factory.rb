FactoryGirl.define do

  factory :base_variant, class: Spree::Variant do
    weight 10
    product { |p| p.association(:base_product) }
    option_values { [create(:option_value)] }
    sequence(:permalink)  {|n| "knitter-1-00#{n}"}

    factory :variant do
      # ensure stock item will be created for this variant
      before(:create) { create(:stock_location) if Spree::StockLocation.count == 0 }
      
      # on_hand 5
      in_stock_cache false
      product

      ignore do
        price 19.99
        currency 'USD'
        sale false
        target nil
      end

      after :create do |i,evaluator|
        create(:price, variant_id: i.id, :currency => evaluator.currency, :amount => evaluator.price, :sale => evaluator.sale)
        if evaluator.target
          create(:variant_target, variant: i, target: evaluator.target)
        end
      end

      factory :part do
        product { |p| p.association(:product, can_be_part: true) }
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
