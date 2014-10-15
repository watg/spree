module Spree
  class ShipmentStockAdjuster
    attr_accessor :shipment, :stock_location

    def initialize(shipment)
      @shipment = shipment
      @stock_location = shipment.stock_location
    end

    def restock(variant, inventory_units)
      inventory_units.group_by(&:supplier).each do |supplier, supplier_units|
        stock_location.restock(variant, supplier_units.count, shipment, supplier)
      end
      Spree::InventoryUnit.where(id: inventory_units.map(&:id)).update_all(supplier_id: nil, pending: true)
    end

    def unstock(variant, inventory_units)
      on_hand_stock_items = available_items(variant).select { |ai| ai.count_on_hand > 0 }

      on_hand, backordered = inventory_units.partition { |iu| iu.state == 'on_hand' }

      # Deal with the on_hand items
      on_hand_stock_items.each do |stock_item|
        break if on_hand.empty?
        slice = on_hand.slice!(0, stock_item.count_on_hand )
        unstock_stock_item(stock_item, slice)
      end

      # Deal with any on_hand that got missed due to the rare
      # occasion when 2 people buy something at the same time
      if on_hand.any?
        if stock_item = on_hand_stock_items.first
          unstock_stock_item(stock_item, on_hand)
        end
      end

      # Deal with the backordered inventory units
      if backordered.any?
        if stock_item = available_items(variant).detect(&:backorderable?)
          unstock_stock_item(stock_item, backordered)
        end
      end

    end

    private

    def available_items(variant)
      @_available_items ||= stock_location.available_stock_items(variant).order(:last_unstocked_at)
    end

    def unstock_stock_item(stock_item, units)

      supplier_id = stock_item.try(:supplier).try(:id)
      Spree::InventoryUnit.where(id: units.map(&:id)).update_all(supplier_id: supplier_id, pending: false)

      adjust_quantity = units.size * -1

      stock_item.stock_movements.create!(
        quantity: adjust_quantity,
        originator: shipment
      )

      # Do not be tempted to moved this into stock_item as this
      # should only happen when a shipment is involved
      stock_item.update_column(:last_unstocked_at, Time.now)
    end

  end

end
