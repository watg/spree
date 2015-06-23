module Spree
  class InventoryUnit < Spree::Base
    belongs_to :variant, class_name: "Spree::Variant", inverse_of: :inventory_units
    belongs_to :order, class_name: "Spree::Order", inverse_of: :inventory_units
    belongs_to :shipment, class_name: "Spree::Shipment", touch: true, inverse_of: :inventory_units
    belongs_to :return_authorization, class_name: "Spree::ReturnAuthorization", inverse_of: :inventory_units
    belongs_to :line_item, class_name: "Spree::LineItem", inverse_of: :inventory_units
    belongs_to :line_item_part, class_name: "Spree::LineItemPart", inverse_of: :inventory_units
    belongs_to :supplier, class_name: "Spree::Supplier", inverse_of: :inventory_units

    has_many :return_items, inverse_of: :inventory_unit
    has_one :product_part, through: :line_item_part
    has_one :original_return_item, class_name: "Spree::ReturnItem", foreign_key: :exchange_inventory_unit_id

    scope :non_pending, -> { where pending: false }
    scope :backordered, -> { where state: 'backordered' }
    scope :awaiting_feed, -> { where state: 'awaiting_feed' }
    scope :on_hand, -> { where state: 'on_hand' }
    scope :waiting_fill, -> { where state: ['awaiting_feed','backordered'] }
    scope :shipped, -> { where state: 'shipped' }
    scope :returned, -> { where state: 'returned' }
    scope :backordered_per_variant, ->(stock_item) do
      includes(:shipment, :order)
        .where("spree_shipments.state != 'canceled'").references(:shipment)
        .where(variant_id: stock_item.variant_id)
        .where('spree_orders.completed_at is not null')
        .backordered.order("spree_orders.completed_at ASC")
    end
    scope :last_24_hours, -> { where(["created_at > ?", 24.hours.ago]) }

    after_save :clear_total_on_hand_cache

    # state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :on_hand do
      event :fill_backorder do
        transition to: :on_hand, from: :backordered
      end
      after_transition on: :fill_backorder, do: :update_order

      event :fill_awaiting_feed do
        transition to: :on_hand, from: :awaiting_feed
      end

      event :ship do
        transition to: :shipped, if: :allow_ship?
      end

      event :return do
        transition to: :returned, from: :shipped
      end
    end

    def fill_waiting_unit
      if backordered?
        fill_backorder
      elsif awaiting_feed?
        fill_awaiting_feed 
      end
    end

    # This was refactored from a simpler query because the previous implementation
    # led to issues once users tried to modify the objects returned. That's due
    # to ActiveRecord `joins(shipment: :stock_location)` only returning readonly
    # objects
    #
    # Returns an array of backordered inventory units as per a given stock item
    def self.backordered_for_stock_item(stock_item)
      backordered_per_variant(stock_item).select do |unit|
        unit.shipment.stock_location == stock_item.stock_location
      end
    end

    def self.waiting_for_stock_item(stock_item)
      where(state: ['backordered', 'awaiting_feed'], variant_id: stock_item.variant_id)
        .includes(:shipment, :order)
        .where("spree_shipments.state != 'canceled'").references(:shipment)
        .where("spree_shipments.stock_location_id = ?", stock_item.stock_location_id)
        .where('spree_orders.completed_at is not null')
        .order("spree_orders.completed_at ASC")
        .partition{ |i| i.shipment.express? }
        .flatten
    end

    def self.total_awaiting_feed_for(variant)
      waiting_fill.non_pending.where(variant: variant).count
    end

    def find_stock_item
      Spree::StockItem.where(stock_location_id: shipment.stock_location_id,
        variant_id: variant_id).first
    end

    # Remove variant default_scope `deleted_at: nil`
    def variant
      Spree::Variant.unscoped { super }
    end

    def current_or_new_return_item
      Spree::ReturnItem.from_inventory_unit(self)
    end

    def additional_tax_total
      line_item.additional_tax_total * percentage_of_line_item
    end

    def included_tax_total
      line_item.included_tax_total * percentage_of_line_item
    end

    private

    def allow_ship?
      self.on_hand?
    end

    def update_order
      self.reload
      order.update!
    end

    def stock_quantifier
      Spree::Stock::Quantifier.new(self.variant)
    end

    def state_change_affects_total_on_hand?
      state_changed? && state_change.any? { |state| state == "awaiting_feed" }
    end

    def clear_total_on_hand_cache
      if state_change_affects_total_on_hand?
        stock_quantifier.clear_total_on_hand_cache
      end
    end


    def percentage_of_line_item
      1 / BigDecimal.new(line_item.quantity)
    end

    def current_return_item
      return_items.not_cancelled.first
    end
  end
end
