module Spree
  module Stock
    class AssemblyQuantifier
      attr_reader :parts

      def initialize(variant)
        @variant = variant
        @parts = @variant.required_parts_for_display
      end
      
      def stock_items
        return @stock_items if @stock_items
        @stock_items = Spree::StockItem.
          joins(:stock_location).
          where(variant_id: parts.map(&:id), Spree::StockLocation.table_name =>{ :active => true})
      end

      def total_on_hand
        parts.inject({}) do |totals, part|
          totals[part.id] =  if Spree::Config.track_inventory_levels
              Spree::StockItem.
                joins(:stock_location).
                where(variant_id: part.id, Spree::StockLocation.table_name =>{ :active => true}).
                sum(:count_on_hand)
            else
              Float::INFINITY
            end
          totals
        end
      end
    
      def backorderable?
        false
      end
      
      def can_supply?(required)
        checks = parts.map do |part|
          total_on_hand[part.id] >= (part.count_part * required)
        end  
        
        checks.inject(true) {|result, part_check| part_check && result}
      end
      
    end
  end
end
