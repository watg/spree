module Spree
  module Stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        return true if line_item.quantity <= 0

        order = line_item.order

        # Get all current line_items, remove the one we want to validate, then add it back
        # ( this covers the case the quantity has changed )
        line_items_to_build = Spree::LineItem.where(order: order).to_a
        line_items_to_build = line_items_to_build.reject { |li| li.id == line_item.id }
        line_items_to_build << line_item

        item_builder = Spree::Stock::OrderItemBuilder.new(line_items_to_build)

        # group the order's variants. Ex: {324=>3, 1405=>4, 321=>2, 323=>3, 322=>3}
        grouped_variants = item_builder.group_variants

        # remove variant ids, which are not part of the line item of interest
        variant_ids_of_interest = item_builder.variant_ids_for_line_item(line_item)
        grouped_variants.slice!(*variant_ids_of_interest)

        # remove variant ids, which have allocated inventory units. Ex {324=>2, 1405=>3, 321=>2}
        grouped_units = order.inventory_units.where(pending: false).group(:variant_id).count

        grouped_variants = grouped_variants.each do |variant_id, count|
          grouped_variants[variant_id] = grouped_variants[variant_id].to_i - grouped_units[variant_id].to_i
        end.select {|v_id, count| count > 0}

        out_of_stock_variants = []
        grouped_variants.each do |variant_id, quantity|
          variant = Spree::Variant.find(variant_id)
          if !Stock::Quantifier.new(variant).can_supply? quantity
            out_of_stock_variants << variant
          end
        end

        if out_of_stock_variants.any?
          line_item.errors[:quantity] << out_of_stock_error_message(out_of_stock_variants)
          false
        else
          true
        end
      end

      def invalid_line_items(order)
        preloader = ActiveRecord::Associations::Preloader.new
        preloader.preload(order, [line_items: :line_item_parts])

        line_items_to_build = Spree::LineItem.where(order: order).to_a
        item_builder = Spree::Stock::OrderItemBuilder.new(line_items_to_build)

        # group the order's variants. Ex: {324=>3, 1405=>4, 321=>2, 323=>3, 322=>3}
        grouped_variants = item_builder.group_variants

        # remove variant ids, which have allocated inventory units. Ex: {324=>2, 1405=>3, 321=>2}
        grouped_units = order.inventory_units.where(pending: false).group(:variant_id).count

        grouped_variants = grouped_variants.each do |variant_id, count|
          grouped_variants[variant_id] = grouped_variants[variant_id].to_i - grouped_units[variant_id].to_i
        end.select {|v_id, count| count > 0}

        variants = Spree::Variant.where(id: grouped_variants.keys)

        variants.map do |variant|
          quantity = grouped_variants[variant.id]

          if !Stock::Quantifier.new(variant).can_supply? quantity
            item_builder.find_by_variant_id(variant.id).last.line_item
          end
        end.compact
      end

      private

      def out_of_stock_error_message(variants)
        display_names = variants.map do |variant|
          display_name = %Q{#{variant.name}}
          display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?
          display_name
        end

        error_message = Spree.t(
          :selected_quantity_not_available, 
          :scope => :order_populator, 
          :item => display_names.to_sentence
        )
        error_message
      end


    end
  end
end
