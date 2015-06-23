FactoryGirl.define do

  factory :base_inventory_unit, class: Spree::InventoryUnit do
    line_item
    variant
    order
    state 'on_hand'
  end

  factory :inventory_unit, class: Spree::InventoryUnit do
    variant
    order
    line_item
    state 'on_hand'
    association(:shipment, factory: :shipment, state: 'pending')
  end
end
