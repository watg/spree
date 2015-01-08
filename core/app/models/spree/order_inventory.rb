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
      if order.completed? || shipment.present?

        if line_item.parts.any?
          process_line_item_parts(@line_item, shipment)
        else
          process_line_item(@line_item, shipment)
        end

      end
    end

    def process_line_item_parts(line_item, shipment)
      parts = line_item.parts.stock_tracking

      old_quantity = (inventory_units.size == 0) ? 0 : inventory_units.size / parts.sum(:quantity)
      quantity_change = line_item.quantity - old_quantity

      if quantity_change > 0

        parts.each do |part|
          quantity_of_parts = part.quantity * quantity_change

          # This is horrible code, and we must change it at some point
          self.variant = part.variant
          shipment = determine_target_shipment unless shipment
          add_to_shipment(shipment, quantity_of_parts, part)

        end

      elsif quantity_change < 0

        parts.each do |part|
          quantity_of_parts = part.quantity * quantity_change

          # This is horrible code, and we must change it at some point
          self.variant = part.variant
          remove_quantity_from_shipment(shipment, quantity_of_parts * -1 )

        end

      else
        # do nothing
      end
    end

    def process_line_item(line_item, shipment)

      quantity_change = line_item.quantity - inventory_units.size

      if quantity_change > 0

        shipment = determine_target_shipment unless shipment
        add_to_shipment(shipment, quantity_change)

      elsif quantity_change < 0

        remove_quantity_from_shipment(shipment, quantity_change * -1 )

      else
        # do nothing
      end

    end

    def inventory_units
      line_item.inventory_units
    end

    private

    def remove_quantity_from_shipment(shipment, quantity)
      if shipment.present?
        remove_from_shipment(shipment, quantity)
      else
        order.shipments.each do |s|
          break if quantity == 0
          quantity -= remove_from_shipment(s, quantity)
        end
      end
    end

    # Returns either one of the shipment:
    #
    # first unshipped that already includes this variant
    # first unshipped that's leaving from a stock_location that stocks this variant
    def determine_target_shipment
      shipment = order.shipments.detect do |s|
        s.ready_or_pending? && s.include?(variant)
      end

      shipment ||= order.shipments.detect do |s|
        s.ready_or_pending? && variant.stock_location_ids.include?(s.stock_location_id)
      end
    end

    def add_to_shipment(shipment, quantity, line_item_part=nil)

      inventory = []
      if variant.should_track_inventory?

        on_hand, backordered, awaiting_feed = shipment.stock_location.fill_status(variant, quantity)

        on_hand.times do
          inventory << shipment.set_up_inventory('on_hand', variant, order, line_item)
        end

        backordered.times do
          inventory << shipment.set_up_inventory('backordered', variant, order, line_item)
        end

        awaiting_feed.times do
          inventory << shipment.set_up_inventory('awaiting_feed', variant, order, line_item)
        end

      else
        quantity.times do
          inventory << shipment.set_up_inventory('on_hand', variant, order, line_item)
        end
      end

      # adding to this shipment, and removing from stock_location
      if order.can_ship?
        Stock::Allocator.new(shipment).unstock(variant, inventory)
      end

      quantity
    end

    def remove_from_shipment(shipment, quantity)
      return 0 if quantity == 0 || shipment.shipped?

      shipment_units = shipment.inventory_units_for_item(line_item, variant).reject do |variant_unit|
        variant_unit.state == 'shipped'
      end.sort_by(&:state)

      remove_units = []

      shipment_units.each do |unit|
        break if remove_units.count == quantity
        remove_units << unit
      end

      # removing this from shipment, and adding to stock_location
      if order.can_ship?
        Stock::Allocator.new(shipment).restock(variant, remove_units)
      end

      removed_quantity = remove_units.count

      remove_units.map(&:destroy)

      shipment.destroy if shipment.inventory_units.count == 0

      removed_quantity
    end
  end
end
