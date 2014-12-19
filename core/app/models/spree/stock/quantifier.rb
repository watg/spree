module Spree
  module Stock
    class Quantifier
      attr_reader :variant

      def initialize(variant)
        @variant = variant
      end

      def total_on_hand
        return Float::INFINITY unless variant.should_track_inventory?

        Rails.cache.fetch(total_on_hand_cache_key) do
          stock_items.to_a.sum(&:count_on_hand) -
            Spree::InventoryUnit.total_awaiting_feed_for(variant)
        end
      end

      def stock_items
        @stock_items ||= StockItem.from_available_locations.
          where(:variant => variant)
      end

      def backorderable?
        Rails.cache.fetch(backorderable_cache_key) do
          stock_items.any?(&:backorderable)
        end
      end

      def can_supply?(required = 1)
        total_on_hand >= required || backorderable?
      end

      def clear_total_on_hand_cache
        Rails.cache.delete(total_on_hand_cache_key)
      end

      def clear_backorderable_cache
        Rails.cache.delete(backorderable_cache_key)
      end

      private

      def total_on_hand_cache_key
        "variant-#{variant.id}-total_on_hand"
      end

      def backorderable_cache_key
        "variant-#{variant.id}-backorderable"
      end

    end
  end
end
