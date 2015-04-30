FactoryGirl.define do
  factory :base_shipment, class: Spree::Shipment do
    tracking 'U10000'
    state 'pending'

    transient do
      cost 100.00
    end

    factory :shipment do
      order
      address
      stock_location

      after(:create) do |shipment, evalulator|
        shipping_method = create(:shipping_method)
        shipment.shipping_rates.create(
         shipping_method: shipping_method, selected: true, cost: evalulator.cost)

        shipment.order.line_items.each do |line_item|
          line_item.quantity.times do
            shipment.inventory_units.create(
              variant_id: line_item.variant_id,
              order_id: shipment.order_id,
              line_item_id: line_item.id
            )
          end
        end

      end
    end

    factory :shipment_light do
      order
      address
      stock_location

      after(:build) do |shipment, evalulator|
        shipping_method = build(:shipping_method)
        shipment.shipping_rates.build(
          shipping_method: shipping_method, selected: true, cost: evalulator.cost)
      end
    end

  end

end
