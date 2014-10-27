module Spree
  module Stock
    class Quantifier
      attr_reader :stock_items

      def initialize(variant, stock_items=nil)
        # Optimisation, in the case of a large order where we want to eager load all the variants
        # and stock item before initializing.
        if stock_items
          @variant = variant
          @stock_items = stock_items
        else
          @variant = resolve_variant_id(variant)
          @stock_items = Spree::StockItem.joins(:stock_location).where(:variant => @variant).merge(StockLocation.available)
        end
      end

      def total_on_hand
        if @variant.should_track_inventory?
          # This used to be
          # stock_items.sum(:count_on_hand)
          # But it requires an extra lookup even though the stock_items are eager loaded hence
          # we do the sum in ruby rather than sql
          stock_items.to_a.sum(&:count_on_hand) -
            Spree::InventoryUnit.total_awaiting_feed_for(@variant)
        else
          Float::INFINITY
        end
      end

      def backorderable?
        stock_items.any?(&:backorderable)
      end

      def can_supply?(required = 1)
        total_on_hand >= required || backorderable?
      end

    private

      # return variant when passed either variant object or variant id
      def resolve_variant_id(variant)
        variant = Spree::Variant.find_by_id(variant) unless variant.respond_to?(:should_track_inventory?)
        variant
      end

    end
  end
end
