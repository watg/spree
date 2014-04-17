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
          @stock_items = Spree::StockItem.joins(:stock_location).where(:variant => @variant, Spree::StockLocation.table_name =>{ :active => true})
        end
      end

      def total_on_hand
        if @variant.should_track_inventory?
          # This used to be
          # stock_items.sum(:count_on_hand)
          # But it requires an extra lookup even though the stock_items are eager loaded hence
          # we do the sum in ruby rather than sql
          stock_items.to_a.sum(&:count_on_hand)
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

          data_set = order.line_items.includes(:line_item_parts).without(desired_line_item)
          a = line_item_to_record[data_set]
          b = ( desired_line_item ? line_item_to_record[desired_line_item] : [] )

          flatten_list_of_items = (a+b)

          variant_quantity_grouping = flatten_list_of_items.reduce({}) {|hsh, c|
                             k = c[:variant_id]
                             hsh[k] ||= 0; hsh[k] += c[:quantity]
                             hsh}


          variant_quantity_grouping_with_stock = eager_load_stock_items( variant_quantity_grouping )

          errors = []
          stock_check = variant_quantity_grouping_with_stock.map {|variant, quantity|
            # We supply stock_items seperately as a way to optimize the initialize
            in_stock = Spree::Stock::Quantifier.new(variant, variant.stock_items).can_supply?(quantity)
            errors << add_error(variant, flatten_list_of_items) unless in_stock
            in_stock}
          result = stock_check.reduce(true) {|can_supply,c| can_supply && c}

          {in_stock: result, errors: errors.flatten}
        end

        def eager_load_stock_items( variant_quantity_grouping )
          variants_with_stock = Spree::Variant.includes(:stock_items =>[:stock_location]).
            where( Spree::StockLocation.table_name =>{ :active => true} ).find(variant_quantity_grouping.keys)

          variants_with_stock.inject({}) do |hash,v| 
            hash[v] = variant_quantity_grouping[v.id]
            hash
          end
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
