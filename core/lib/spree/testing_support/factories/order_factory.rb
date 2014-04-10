FactoryGirl.define do
  factory :order, class: Spree::Order do
    user
    bill_address
    completed_at nil
    email { user.email }
    created_at Time.now
    currency 'USD'

    factory :order_with_totals do
      after(:create) do |order|
        create(:line_item, order: order)
        order.line_items.reload # to ensure order.line_items is accessible after
      end
    end

    factory :order_ready_to_ship do
      bill_address
      ship_address
      payment_state 'paid'
      shipment_state 'ready'
      state 'complete'

      ignore do
        line_items_count 1
        stock_location { create(:stock_location) }
      end
      
      after(:create) do |order, evaluator|
        create(:payment, amount: order.total, order: order, state: 'completed')
        create(:shipment, order: order, state: 'ready')
        order.shipments.each do |shipment|
          shipment.inventory_units.each { |u| u.update_column('state', 'on_hand') }
        end
        order.update!
        # order.line_items << create_list(:line_item, evaluator.line_items_count, order: order)
      end
 
      factory :invoice_printed_order do
        sequence(:batch_print_id)
        batch_invoice_print_date { Date.today }

        factory :image_sticker_printed_order do
          batch_sticker_print_date { Date.today }
        end
      end

    end

    factory :order_with_line_items do
      bill_address
      ship_address

      ignore do
        line_items_count 5
      end

      after(:create) do |order, evaluator|
        create(:shipment, order: order)
        order.shipments.reload

        create_list(:line_item, evaluator.line_items_count, order: order)
        order.line_items.reload

        order.update!
      end

      factory :completed_order_with_totals do
        state 'complete'

        after(:create) do |order|
          order.refresh_shipment_rates
          order.update_column(:completed_at, Time.now)
        end

        factory :completed_order_with_pending_payment do
          payment_state 'balance due'
          shipment_state 'pending'
          after(:create) do |order|
            create(:payment, amount: order.total, order: order, state: 'pending')
            order.shipments.each do |shipment|
              shipment.inventory_units.each { |u| u.update_column('state', 'on_hand') }
              shipment.update_column('state', 'ready')
            end
            order.reload
          end
        end

        factory :order_with_pattern_only_ready_to_be_consigned_and_allocated do
          payment_state 'paid'
          shipment_state 'ready'
          after(:create) do |order|
            order.line_items.delete_all
            create(:line_item, quantity: 1, variant: create(:pattern).master, order: order)
            create(:parcel, order: order, box_id: create(:box).id)
            create(:payment, amount: order.total, order: order, state: 'completed')
            order.shipments.each do |shipment|
              shipment.inventory_units.each { |u| u.update_column('state', 'on_hand') }
              shipment.update_column('state', 'ready')
            end
            order.reload
          end
        end

        factory :order_with_ten_pattern_only_ready_to_be_consigned_and_allocated do
          payment_state 'paid'
          shipment_state 'ready'
          
          ignore do
            line_items_count 10
          end

          after(:create) do |order, evaluator|
            order.line_items.delete_all
            create_list(:line_item, evaluator.line_items_count, variant: create(:pattern).master, order: order)
            create(:parcel, order: order, box_id: create(:box).id)
            create(:payment, amount: order.total, order: order, state: 'completed')
            order.shipments.each do |shipment|
              shipment.inventory_units.each { |u| u.update_column('state', 'on_hand') }
              shipment.update_column('state', 'ready')
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
            create(:payment, amount: order.total, order: order, state: 'completed')
            order.shipments.each do |shipment|
              shipment.inventory_units.each { |u| u.update_column('state', 'on_hand') }
              shipment.update_column('state', 'ready')
            end
            order.reload
          end

          factory :allocated_order do
            metapack_allocated true
          end
        end

        factory :shipped_order do
          after(:create) do |order|
            order.shipments.each do |shipment|
              shipment.inventory_units.each { |u| u.update_column('state', 'shipped') }
              shipment.update_column('state', 'shipped')
            end
            order.reload
          end
        end

      end
    end
  end
end
