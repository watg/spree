FactoryGirl.define do
  factory :order, class: Spree::Order do
    user
    bill_address
    # do not be tempted to add ship_address, it will break the shipping_spec
    completed_at nil
    email { user.email }
    created_at Time.now
    currency 'USD'

    association :order_type, factory: :order_type, strategy: :build

    transient do
      line_items_price BigDecimal.new(10)
    end

    factory :order_with_totals do
      after(:create) do |order, evaluator|
        create(:line_item, order: order, price: evaluator.line_items_price)
        order.line_items.reload # to ensure order.line_items is accessible after
      end
    end

    factory :order_with_line_items do
      bill_address
      ship_address

      transient do
        line_items_count 1
        shipment_cost 100
      end

      trait :with_marketing_type do
        after(:create) do |order, evaluator|
          order.line_items.first.variant.product.update_column(:marketing_type_id, create(:marketing_type).id)
        end
      end

      trait :with_product_group do
        after(:create) do |order, evaluator|
          order.line_items.first.variant.product.update_column(:product_group_id, create(:product_group).id)
        end
      end

      after(:create) do |order, evaluator|
        create_list(:line_item, evaluator.line_items_count, order: order, price: evaluator.line_items_price)
        order.line_items.reload

        order.shipments << create(:shipment, order: order, cost: evaluator.shipment_cost)

        order.update!
      end

      factory :completed_order do
        state 'complete'

        transient do
          completed_at Time.now
        end

        after(:create) do |order, evaluator|
          order.update_column(:completed_at, evaluator.completed_at)
        end
      end

      factory :completed_order_with_totals do
        state 'complete'

        transient do
          completed_at Time.now
        end

        after(:create) do |order, evaluator|
          order.update_column(:completed_at, evaluator.completed_at)
        end

        factory :completed_order_with_pending_payment do
          after(:create) do |order|
            create(:payment, amount: order.total, order: order)
          end
        end

        factory :order_ready_to_ship do
          payment_state 'paid'
          shipment_state 'ready'

          after(:create) do |order|
            create(:payment, amount: order.total, order: order, state: 'completed')
            order.shipments.each do |shipment|
              shipment.inventory_units.update_all state: 'on_hand'
              shipment.update_column('state', 'ready')
            end
            order.reload
          end
        end

        factory :shipped_order do
          payment_state 'paid'
          shipment_state 'shipped'

          after(:create) do |order|
            create(:payment, amount: order.total, order: order, state: 'completed')
            order.shipments.each do |shipment|
              shipment.inventory_units.update_all state: 'shipped'
              shipment.update_column('state', 'shipped')
            end
            order.reload
          end
        end

        factory :order_ready_to_be_consigned_and_allocated do
          payment_state 'paid'
          shipment_state 'ready'
          after(:create) do |order|
            create(:parcel, order: order, box_id: create(:box).id)
            create(:parcel, order: order, box_id: create(:box).id)
            order.shipments.each do |shipment|
              shipment.inventory_units.each do |u|
                u.update_columns(state: 'on_hand', supplier_id: create(:supplier))
              end
              shipment.update_column('state', 'ready')
            end
            order.reload
          end

        end
      end
    end
  end
end
