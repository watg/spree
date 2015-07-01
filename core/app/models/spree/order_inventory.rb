module Spree
  class OrderInventory
    attr_accessor :order, :line_item, :variant

    def initialize(order, line_item)
      @order = order
      @line_item = line_item
      @variant = line_item.variant
    end

    # Only verify inventory for completed orders (as orders in frontend checkout
    # have inventory assigned via +order.create_proposed_shipment+) or when
    # shipment is explicitly passed
    #
    # In case shipment is passed the stock location should only unstock or
    # restock items if the order is completed. That is so because stock items
    # are always unstocked when the order is completed through +shipment.finalize+
    #
    def verify(shipment = nil)
      return unless order.completed? || shipment.present?
      @shipment = shipment
      process_line_item(@line_item, shipment) unless kit
      process_line_item_parts(shipment)
    end

    private

    def process_line_item(line_item, shipment)
      quantity_change = line_item.quantity - inventory_units.size
      if quantity_change > 0
        add_to_shipment(quantity_change, nil, line_item.variant)
      elsif quantity_change < 0
        remove_quantity_from_shipment(shipment, quantity_change * -1, line_item.variant)
      end
    end

    def add_to_shipment(quantity, line_item_part = nil, variant = nil)
      inventory = []
      if variant.should_track_inventory?
        on_hand, backordered, awaiting_feed = fill_status(variant, quantity)

        on_hand.times do
          inventory << target_shipment.set_up_inventory(
            "on_hand", variant, order, line_item, line_item_part)
        end

        backordered.times do
          inventory << target_shipment.set_up_inventory(
            "backordered", variant, order, line_item, line_item_part)
        end

        awaiting_feed.times do
          inventory << target_shipment.set_up_inventory(
            "awaiting_feed", variant, order, line_item, line_item_part)
        end

      else
        quantity.times do
          inventory << target_shipment.set_up_inventory(
            "on_hand", variant, order, line_item, line_item_part)
        end
      end

      # adding to this shipment, and removing from stock_location
      if order.can_allocate_stock?
        Stock::Allocator.new(target_shipment).unstock(variant, inventory)
      end

      quantity
    end

    def fill_status(variant, quantity)
      target_shipment.stock_location.fill_status(variant, quantity)
    end

    def target_shipment
      @shipment || determine_target_shipment
    end

    # Returns either one of the shipment:
    #
    # first unshipped that already includes this variant
    # first unshipped that's leaving from a stock_location that stocks this variant
    def determine_target_shipment
      shipment = order.shipments.detect do |s|
        s.waiting_to_ship? && s.include?(variant)
      end

      shipment || order.shipments.detect do |s|
        s.waiting_to_ship? && variant.stock_location_ids.include?(s.stock_location_id)
      end
    end

    def process_line_item_parts(shipment)
      return unless parts.any?

      if quantity_change > 0
        parts.each do |part|
          quantity_of_parts = part.quantity * quantity_change
          add_to_shipment(quantity_of_parts, part, part.variant)
        end

      elsif quantity_change < 0
        parts.each do |part|
          quantity_of_parts = part.quantity * quantity_change
          remove_quantity_from_shipment(shipment, quantity_of_parts * -1, part.variant)
        end
      end
    end

    def parts
      @parts ||= line_item.parts.stock_tracking
    end

    def quantity_change
      @quantity_change ||= line_item.quantity - old_quantity
    end

    def old_quantity
      (inventory_units.size == 0) ? 0 : inventory_units.size / parts.sum(:quantity)
    end

    def inventory_units
      line_item.inventory_units
    end

    def kit
      line_item.variant.product.product_type.kit?
    end

    def remove_quantity_from_shipment(shipment, quantity, variant = nil)
      if shipment.present?
        remove_from_shipment(shipment, quantity, variant)
      else
        order.shipments.each do |s|
          break if quantity == 0
          quantity -= remove_from_shipment(s, quantity, variant)
        end
      end
    end

    def remove_from_shipment(shipment, quantity, variant)
      return 0 if quantity == 0 || shipment.shipped?

      shipment_inventory_units = shipment.inventory_units_for_item(line_item, variant)
      shipment_units = shipment_inventory_units.reject do |variant_unit|
        variant_unit.state == "shipped"
      end.sort_by(&:state)

      remove_units = []

      shipment_units.each do |unit|
        break if remove_units.count == quantity
        remove_units << unit
      end

      # removing this from shipment, and adding to stock_location
      if order.can_allocate_stock?
        Stock::Allocator.new(shipment).restock(variant, remove_units)
      end

      removed_quantity = remove_units.count

      remove_units.map(&:destroy)

      if shipment.inventory_units.count == 0
        ::Shipments::Deleter.new(shipment).delete
      end

      removed_quantity
    end
  end
end
