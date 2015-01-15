module Spree
  class StockItem < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :stock_location, class_name: 'Spree::StockLocation'
    belongs_to :supplier, class_name: 'Spree::Supplier'

    belongs_to :variant, class_name: 'Spree::Variant', inverse_of: :stock_items
    has_many :stock_movements, inverse_of: :stock_item

    validates_presence_of :stock_location, :variant
    validates_uniqueness_of :variant_id, scope: [:stock_location_id, :deleted_at, :supplier_id]

    delegate :weight, :should_track_inventory?, to: :variant

    after_save :conditional_variant_touch
    after_save :conditional_clear_total_on_hand_cache
    after_destroy :clear_total_on_hand_cache
    after_save :clear_backorderable_cache

    after_touch { variant.touch }

    scope :available, -> { where("count_on_hand > 0 or backorderable = true") }
    scope :active, -> { joins(:stock_location).where(Spree::StockLocation.table_name =>{ :active => true}) }

    scope :from_available_locations, -> do
       Spree::StockItem.joins(:stock_location).merge(StockLocation.available)
    end

    def waiting_inventory_unit_count
      variant.total_awaiting_feed
    end

    def variant_name
      variant.name
    end

    def adjust_count_on_hand(value)
      self.with_lock do
        self.count_on_hand = self.count_on_hand + value
        self.save!
      end
      process_waiting_inventory_units(value)
    end

    def set_count_on_hand(value)
      self.count_on_hand = value
      delta = count_on_hand - count_on_hand_was
      self.save!
      process_waiting_inventory_units(delta)
    end

    def in_stock?
      self.count_on_hand > 0
    end

    # Tells whether it's available to be included in a shipment
    def available?
      self.in_stock? || self.backorderable?
    end

    def number_of_shipments_pending
      pending =  Spree::InventoryUnit.where(variant_id: self.variant_id, state: :on_hand, pending: false).
        joins(:order, :shipment).merge(Spree::Order.shippable_state).
        where('spree_shipments.state in (?)', %w{ready}).
        where('spree_shipments.stock_location_id = ?', self.stock_location_id)
      supplier_id = self.supplier ? self.supplier.id : nil
      pending = pending.where(supplier_id: supplier_id)
      pending.count
    end

  private

    def count_on_hand=(value)
      write_attribute(:count_on_hand, value)
    end

    # Process backorders based on amount of stock received
    # If stock was -20 and is now -15 (increase of 5 units), then we should process 5 inventory orders.
    # If stock was -20 but then was -25 (decrease of 5 units), do nothing.
    def process_waiting_inventory_units(quantity)
      if quantity > 0
        waiting_units_processor.perform(quantity)
      end
    end

    def waiting_units_processor
      Spree::Stock::WaitingUnitsProcessor.new(self)
    end

    # There is a potential race condition here that could be triggered if you
    # change the way this method works. At present stock transfers involve two
    # adjustments to count on hand - one for the location you're moving it out
    # of and one for the location you're moving it into. However both
    # adjustments potentially create jobs to invalidate the cache. Thus it is
    # theoretically possible that the job to invalidate the cache will run when
    # the stock is 'in transit'.
    #
    # Normally this won't be too bad as the second update will also trigger the
    # cache invalidation so the value will only be wrong very briefly. However
    # if stock is being moved from a feeder store into an active store there is
    # the potential that the invalidation won't be triggered because the stock
    # moved into it will be allocated to waiting orders, and the count_on_hand
    # won't change.
    #
    # This will never be a problem if only the boolean 'in_stock?' is being
    # cached. The answer to this question won't be wrong when stock is
    # 'in transit'. However if we start caching the count on hand then there is
    # a risk that the cache will get invalidated as the value goes negative
    # (stock has left the feeder location and not appeared in the active, but we
    # still have inventory units waiting for it) and then not get corrected when
    # the stock arrives in the active location (as the count_on_hand won't
    # change, although the inventory units' state will change).
    #
    # It is tempting to think that we could fix this by wrapping transfers in a
    # database transaction. This would be the case so long as we're using
    # DelayedJob (or some other database backed queue). If we were using a non-
    # database queue then there is the potential that the job would trigger
    # before the transaction finishes, and thus recalulate before the values
    # have been updated.
    #
    # The 'correct' solution to all of this would probably be to create an
    # abstraction for adjusting stock, make sure the rest of the code always
    # goes via this abstraction and then make the abstraction responsible for
    # creating the cache invalidation job once it knows all the updates have
    # finished.
    def conditional_variant_touch
      if !Spree::Config.binary_inventory_cache || stock_changed?
        ::Delayed::Job.enqueue Spree::StockCheckJob.new(variant), queue: 'stock_check', priority: 10
      end
    end

    def stock_quantifier
      Spree::Stock::Quantifier.new(self.variant)
    end

    def conditional_clear_total_on_hand_cache
      if count_on_hand_changed? || variant_id_changed?
        clear_total_on_hand_cache
      end
    end

    def clear_total_on_hand_cache
      stock_quantifier.clear_total_on_hand_cache
    end

    def clear_backorderable_cache
      if backorderable_changed? || variant_id_changed?
        stock_quantifier.clear_backorderable_cache
      end
    end

    # the variant_id changes from nil when a new stock location is added
    def stock_changed?
      @stock_chagned ||= (count_on_hand_changed? && count_on_hand_change.any?(&:zero?)) || variant_id_changed?
    end



  end


end
