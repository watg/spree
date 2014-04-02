module Spree
  module Stock
    class Quantifier
      attr_reader :stock_items

      def initialize(variant)
        @variant = resolve_variant_id(variant)
        @stock_items = Spree::StockItem.joins(:stock_location).where(:variant_id => @variant, Spree::StockLocation.table_name =>{ :active => true})
      end

      def total_on_hand
        if Spree::Config.track_inventory_levels
          stock_items.sum(:count_on_hand)
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

      # return variant when passed either variant object or variant id
      def resolve_variant_id(variant)
        variant = Spree::Variant.find_by_id(variant) unless variant.respond_to?(:should_track_inventory?)
        variant
      end

      class << self

        def can_supply_order?(order, desired_line_item=nil)
          line_item_to_record = lambda do |li|
            [li].flatten.map do |line_item|
              d  = []
              d << { line_item_id: line_item.id,
                variant_id: line_item.variant_id, 
                quantity:   line_item.quantity }
              line_item.line_item_parts.each do |pa|
                d << {
                  line_item_id: line_item.id,
                  variant_id:   pa.variant_id,
                  quantity:     pa.quantity * line_item.quantity
                }
              end
              d
            end.flatten
          end

          data_set = order.line_items.without(desired_line_item)
          a = line_item_to_record[data_set]
          b = ( desired_line_item ? line_item_to_record[desired_line_item] : [] )
          
          flatten_list_of_items = (a+b)
          
          variant_quantity_grouping = flatten_list_of_items.reduce({}) {|hsh, c|
                             k = c[:variant_id]
                             hsh[k] ||= 0; hsh[k] += c[:quantity]
                             hsh}

          errors = []
          stock_check = variant_quantity_grouping.map {|variant_id, quantity|
                            variant = Spree::Variant.find(variant_id)
                            in_stock = Spree::Stock::Quantifier.new(variant).can_supply?(quantity)
                            errors << add_error(variant, flatten_list_of_items) unless in_stock
                            in_stock}
          result = stock_check.reduce(true) {|can_supply,c| can_supply && c}

          {in_stock: result, errors: errors.flatten}
        end

        def add_error(variant, list_of_existing_li)
          li_with_out_of_stock_variants = list_of_existing_li.select {|e| e[:variant_id] == variant.id}
          li_with_out_of_stock_variants << {} if li_with_out_of_stock_variants.empty?
          li_with_out_of_stock_variants.map do |li|
            {
              line_item_id: li[:line_item_id],
              msg: Spree.t(:out_of_stock, :scope => :order_populator, :item => %Q{#{variant.name} #{variant.options_text}}.inspect)
            }
          end
        end
      end

    end
  end
end
