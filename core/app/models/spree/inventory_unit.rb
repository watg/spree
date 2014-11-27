module Spree
  class InventoryUnit < ActiveRecord::Base
    belongs_to :variant, class_name: "Spree::Variant", inverse_of: :inventory_units
    belongs_to :order, class_name: "Spree::Order", inverse_of: :inventory_units
    belongs_to :shipment, class_name: "Spree::Shipment", touch: true, inverse_of: :inventory_units
    belongs_to :return_authorization, class_name: "Spree::ReturnAuthorization"
    belongs_to :line_item, class_name: "Spree::LineItem", inverse_of: :inventory_units
    belongs_to :line_item_part, class_name: "Spree::LineItemPart", inverse_of: :inventory_units
    belongs_to :supplier, class_name: "Spree::Supplier", inverse_of: :inventory_units

    scope :non_pending, -> { where pending: false }
    scope :backordered, -> { where state: 'backordered' }
    scope :awaiting_feed, -> { where state: 'awaiting_feed' }
    scope :shipped, -> { where state: 'shipped' }
    scope :backordered_per_variant, ->(stock_item) do
      includes(:shipment, :order)
        .where("spree_shipments.state != 'canceled'").references(:shipment)
        .where(variant_id: stock_item.variant_id)
        .where('spree_orders.completed_at is not null')
        .backordered.order("spree_orders.completed_at ASC")
    end
    scope :last_24_hours, -> { where(["created_at > ?", 24.hours.ago]) }

    # state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
    state_machine initial: :on_hand do
      event :fill_backorder do
        transition to: :on_hand, from: :backordered
      end
      after_transition on: :fill_backorder, do: :update_order

      event :fill_awaiting_feed do
        transition to: :on_hand, from: :awaiting_feed
      end
      after_transition on: :fill_awaiting_feed, do: :update_order

      event :ship do
        transition to: :shipped, if: :allow_ship?
      end

      event :return do
        transition to: :returned, from: :shipped
      end
    end

    # This was refactored from a simpler query because the previous implementation
    # lead to issues once users tried to modify the objects returned. That's due
    # to ActiveRecord `joins(shipment: :stock_location)` only return readonly
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
    end

    def self.total_awaiting_feed_for(variant)
      awaiting_feed.non_pending.where(variant: variant).count
    end

    def self.finalize_units!(inventory_units)
      inventory_units.map do |iu|
        iu.update_columns(
          pending: false,
          updated_at: Time.now,
        )
      end
    end

    def find_stock_item
      Spree::StockItem.where(stock_location_id: shipment.stock_location_id,
        variant_id: variant_id).first
    end

    # Remove variant default_scope `deleted_at: nil`
    def variant
      Spree::Variant.unscoped { super }
    end

    private

      def allow_ship?
        Spree::Config[:allow_backorder_shipping] || self.on_hand?
      end

      def update_order
        order.update!
      end
  end
end

