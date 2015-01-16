FactoryGirl.define do
  factory :base_product, class: Spree::Product do
    sequence(:name) { |n| "Product ##{n} - #{Kernel.rand(9999)}" }
    description { generate(:random_description) }
    cost_price 17.00
    sku { generate(:sku) }
    available_on { 1.year.ago }
    deleted_at nil
    individual_sale true
    weight 0.25

    association :product_group, factory: :product_group, strategy: :build
    association :product_type, factory: :product_type, strategy: :build
    association :marketing_type, factory: :marketing_type, strategy: :build
    shipping_category { |r| Spree::ShippingCategory.first || r.association(:shipping_category) }

    transient do
      amount nil
      currency 'USD'
    end

    after(:build) do |i,evaluator|
      if evaluator.amount
        i.price_normal_in(evaluator.currency).amount = evaluator.amount
      end
    end

    #after(:create) do |p|
    #  p.variants_including_master.each { |v| v.save! }
    #end

    factory :product, aliases: [:rtw, :kit, :virtual_product] do

      transient do
        amount 19.99
      end

      tax_category { |r| Spree::TaxCategory.first || r.association(:tax_category) }

      # ensure stock item will be created for this products master
      before(:create) { create(:stock_location) if Spree::StockLocation.count == 0 }

      factory :product_with_option_types do
        after(:create) { |product| create(:product_option_type, product: product) }
      end

    end

    factory :product_with_prices do
      transient do
        usd_price 19.99
        gbp_price 19.99
        eur_price 19.99
        usd_currency 'USD'
        gbp_currency 'GBP'
        eur_currency 'EUR'
      end

      before :create do |i,evaluator|
        i.master.price_normal_in(evaluator.gbp_currency).amount = evaluator.gbp_price
        i.master.price_normal_in(evaluator.eur_currency).amount = evaluator.eur_price
        i.master.price_normal_in(evaluator.usd_currency).amount = evaluator.usd_price
      end
    end

    factory :pattern do
      sequence(:name) {|e| "Pattern #{e}" }
      product_type :pattern
    end

    factory :box do
      sequence(:name) {|n| "Box size #{n}"}
      weight 0.3
      height 20.0
      width 40.0
      depth 5.0
      product_type { create(:product_type_packaging) }

      after(:create) do |box|
        bg = create(:box_group)
        _product_group_id = bg.id
        box.save
      end
    end

    factory :custom_product, class: Spree::Product do
      name 'Custom Product'
      description { generate(:random_description) }
      sku 'ABC'
      available_on { 1.year.ago }
      deleted_at nil

      tax_category { |r| Spree::TaxCategory.first || r.association(:tax_category) }
      shipping_category { |r| Spree::ShippingCategory.first || r.association(:shipping_category) }
    end

    factory :product_with_stock do
      after :create do |object, evaluator|
        object.master.in_stock_cache = true
        object.stock_items.each { |si| si.adjust_count_on_hand(10) }
      end
    end

	factory :product_in_stock do
      after :create do |object, evaluator|
        object.master.in_stock_cache = true
        object.stock_items.each { |si| si.adjust_count_on_hand(10) }
      end
    end

    factory :product_with_stock_and_prices do
      transient do
        usd_price 19.99
        gbp_price 19.99
        eur_price 19.99
        usd_currency 'USD'
        gbp_currency 'GBP'
        eur_currency 'EUR'
      end

      # ensure stock item will be created for this products master
      before(:create) { create(:stock_location) if Spree::StockLocation.count == 0 }

      before :create do |i,evaluator|
        i.stock_items.each { |si| si.adjust_count_on_hand(10) }
        i.master.in_stock_cache = true
        i.master.price_normal_in(evaluator.gbp_currency).amount = evaluator.gbp_price
        i.master.price_normal_in(evaluator.eur_currency).amount = evaluator.eur_price
        i.master.price_normal_in(evaluator.usd_currency).amount = evaluator.usd_price
        #i.master.save
      end

    end

    factory :product_with_variants do
      transient do
        amount 0.00
        number_of_variants 2
      end

      after :create do |p, evaluator|
        evaluator.number_of_variants.times do
          p.variants << FactoryGirl.create(:variant, product_id: p.id, amount: evaluator.amount)
        end
      end

    end

  end
end
