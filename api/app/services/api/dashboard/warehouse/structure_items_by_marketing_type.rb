module Api
  module Dashboard
    module Warehouse
      # requires a column named marketing_type_title
      # requires a column named quantity
      # returns a structured version by marketing_type_title
      # of line items of a given order collection
      class StructureItemsByMarketingType
        def initialize(validated_orders)
          @orders = validated_orders
        end

        def run
          # debugger
          orders = @orders.group_by(&:marketing_type_title).map do |key, line_items|
            # debugger
            { key => line_items.map(&:quantity).reduce(:+) }
          end
          orders = Hash[*orders.collect(&:to_a).flatten]
          orders.sort_by { |hsh| - hsh.last } # orders the array by value in desc
        end
      end
    end
  end
end
