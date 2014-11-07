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
    after_touch { variant.touch }

    scope :available, -> { where("count_on_hand > 0 or backorderable = true") }

    def backordered_inventory_units
      Spree::InventoryUnit.backordered_for_stock_item(self)
    end

    def variant_name
      variant.name
    end

    def adjust_count_on_hand(value)
      self.with_lock do
        self.count_on_hand = self.count_on_hand + value
        process_backorders(count_on_hand - count_on_hand_was)
        self.save!
      end
    end

    def set_count_on_hand(value)
      self.count_on_hand = value
      process_backorders(count_on_hand - count_on_hand_was)

      self.save!
    end

    def in_stock?
      self.count_on_hand > 0
    end

    # Tells whether it's available to be included in a shipment
    def available?
      self.in_stock? || self.backorderable?
    end

    private
    def count_on_hand=(value)
      write_attribute(:count_on_hand, value)
    end

    # Process backorders based on amount of stock received
    # If stock was -20 and is now -15 (increase of 5 units), then we should process 5 inventory orders.
    # If stock was -20 but then was -25 (decrease of 5 units), do nothing.
    def process_backorders(number)
      if number > 0
        backordered_inventory_units.first(number).each do |unit|
          unit.fill_backorder
        end
      end
    end

    def conditional_variant_touch
      # the variant_id changes from nil when a new stock location is added
      stock_changed = (count_on_hand_changed? && count_on_hand_change.any?(&:zero?)) || variant_id_changed?

      if !Spree::Config.binary_inventory_cache || stock_changed
        ::Delayed::Job.enqueue Spree::StockCheckJob.new(variant), queue: 'stock_check', priority: 10
      end
    end

  end
end
