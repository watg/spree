module Spree
  class Stock::Allocator
    attr_accessor :shipment, :stock_location

    def initialize(shipment)
      @shipment = shipment
      @stock_location = shipment.stock_location
    end

    def restock(variant, inventory_units)

      # Do not be tempted to do update_all, as this will not trigger the cache purge
      # for the total_on_hand
      inventory_units.each do |iu|
        iu.supplier_id = nil
        iu.pending = true
        iu.save
      end

      if restockable_inventory_units = inventory_units.select(&:on_hand?)
        restock_on_hand(variant, restockable_inventory_units)
      end

    end

    def unstock(variant, inventory_units)

      # Do not be tempted to do update_all, as this will not trigger the cache purge
      # for the total_on_hand
      inventory_units.each do |iu|
        iu.pending = false
        iu.save
      end

      if on_hand = inventory_units.select(&:on_hand?)
        unstock_on_hand(variant, on_hand)
      end

    end

    def restock_on_hand(variant, restockable_inventory_units)
      restockable_inventory_units.group_by(&:supplier).each do |supplier, supplier_units|
        stock_location.restock(variant, supplier_units.count, shipment, supplier)
      end
    end

    def unstock_on_hand(variant, on_hand)

      # Deal with on_hand items.
      problem_on_hand = allocate_from_on_hand_stock(variant, on_hand)

      if problem_on_hand.any?
        # Something has gone wrong. Stock that was on hand is no longer on hand.
        # Try to allocate from feeder stock instead.
        problem_on_hand = allocate_from_feeder_stock(variant, problem_on_hand)
      end

      if problem_on_hand.any?
        # This is getting worse. There is no stock on hand or in feeders. Maybe
        # we can backorder the stock?
        problem_on_hand = allocate_from_backorder(variant, problem_on_hand)
      end

      if problem_on_hand.any?
        # OK, this is getting silly. We sold this but there is no stock anywhere
        # and we can't backorder it. Let's allocate it from anywhere and force
        # the stock to be negative somewhere.
        unstock_stock_item(available_items(variant).first, problem_on_hand)
      end

    end

    private

    def allocate_from_on_hand_stock(variant, inventory_units)
      units = inventory_units.dup
      on_hand_stock_items(variant).each do |stock_item|
        break if units.empty?
        slice = units.shift(stock_item.count_on_hand)
        unstock_stock_item(stock_item, slice)
      end
      units
    end

    def allocate_from_feeder_stock(variant, inventory_units)
      units = inventory_units.dup
      feeder_stock_items(variant).each do |stock_item|
        units.shift(stock_item.count_on_hand).each do |iu|
          iu.state = :awaiting_feed
          iu.save
        end
      end
      units
    end

    def allocate_from_backorder(variant, units)
      return units if units.empty?
      stock_item = backorderable_stock_item(variant)
      if stock_item
        units.each do |iu|
          unless iu.backordered?
            iu.state = :backordered
            iu.save
          end
        end
        [] # there is nothing left to allocate
      else
        units
      end
    end

    def on_hand_stock_items(variant)
      available_items(variant).select { |ai| ai.count_on_hand > 0 }
    end

    def backorderable_stock_item(variant)
      available_items(variant).detect(&:backorderable?)
    end

    def feeder_stock_items(variant)
      stock_location.feeder_items(variant)
    end

    def available_items(variant)
      @available_items ||= {}
      @available_items[variant] ||= stock_location.available_stock_items(variant).order('last_unstocked_at NULLS FIRST')
      @available_items[variant]
    end

    def unstock_stock_item(stock_item, units)

      supplier = stock_item.try(:supplier)
      if supplier.nil?
        Helpers::AirbrakeNotifier.notify(
          "Stock Item has no supplier",
          {stock_item_id: stock_item.id}
        )
      end

      # Do not be tempted to do update_all, as this will not trigger the cache purge
      # for the total_on_hand
      units.each do |iu|
        iu.supplier = supplier
        iu.save
      end

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
