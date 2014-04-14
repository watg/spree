FactoryGirl.define do
  factory :base_product, class: Spree::Product do
    sequence(:name) { |n| "Tala Tank product #{n}" }
    sku 'ABC'

    available_on { 1.day.ago }
    deleted_at nil
    product_type 'product'
    individual_sale true

    weight 0.25
    price 19.99
    cost_price 0.25

    association :product_group, factory: :product_group, strategy: :build
    association :gang_member, factory: :gang_member, strategy: :build
    shipping_category { |r| Spree::ShippingCategory.first || r.association(:shipping_category) }

    after(:create) do |p|
      p.variants_including_master.each { |v| v.save! }
    end
    
    factory :product, aliases: [:rtw, :kit, :virtual_product] do
      tax_category { |r| Spree::TaxCategory.first || r.association(:tax_category) }
      
      # ensure stock item will be created for this products master
      before(:create) { create(:stock_location) if Spree::StockLocation.count == 0 }
      
      factory :product_with_option_types do
        after(:create) { |product| create(:product_option_type, product: product) }
      end
    end


    factory :product_with_prices do
      ignore do
        usd_price 19.99
        gbp_price 19.99
        eur_price 19.99
        usd_currency 'USD'
        gbp_currency 'GBP'
        eur_currency 'EUR'
      end

      price { usd_price }

      after :create do |i,evaluator|
        create(:price, variant_id: i.master.id, :currency => evaluator.gbp_currency, :amount => evaluator.gbp_price)
        create(:price, variant_id: i.master.id, :currency => evaluator.eur_currency, :amount => evaluator.eur_price)
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
      product_type :parcel

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

      # association :taxons
    end

    factory :product_with_one_taxon do
      after :create do |p|
        t = FactoryGirl.build(:taxon)
        p.taxons << t
        p.save
      end
    end

    factory :product_with_stock do      
      after :create do |object, evaluator| 
        object.master.in_stock_cache = true
        object.stock_items.each { |si| si.adjust_count_on_hand(10) }
      end
    end

    factory :product_with_stock_and_prices do
      ignore do
        usd_price 19.99
        gbp_price 19.99
        eur_price 19.99
        usd_currency 'USD'
        gbp_currency 'GBP'
        eur_currency 'EUR'
      end

      price { usd_price }

      # ensure stock item will be created for this products master
      before(:create) { create(:stock_location) if Spree::StockLocation.count == 0 }

      after :create do |i,evaluator|
        i.stock_items.each { |si| si.adjust_count_on_hand(10) }
        i.master.in_stock_cache = true
        i.master.save
        create(:price, variant_id: i.master.id, :currency => evaluator.gbp_currency, :amount => evaluator.gbp_price)
        create(:price, variant_id: i.master.id, :currency => evaluator.eur_currency, :amount => evaluator.eur_price)
      end

    end

    factory :product_with_variants do
      ignore do
        number_of_variants 2
      end

      after :create do |p, evaluator|
        evaluator.number_of_variants.times do
          p.variants << FactoryGirl.create(:variant, product_id: p.id)
        end
      end

      factory :product_with_variants_displayable do
        ignore do
          displayable 2
        end

        after :create do |p, evaluator|
          p.taxons << FactoryGirl.build(:taxon)
          p.variants.first(evaluator.displayable).each do |v|
            Spree::DisplayableVariant.create(product_id: p.id, variant_id: v.id, taxon_id: p.taxons.first.id )
          end
          p.save
        end
      end
    end
    
  end
end
