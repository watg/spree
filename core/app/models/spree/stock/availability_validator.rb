module Spree
  module Stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        order = line_item.order
        item_builder = Spree::Stock::OrderItemBuilder.new(order)

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

        valid = grouped_variants.all? do |variant_id, quantity|
          variant = Spree::Variant.find(variant_id)
          Stock::Quantifier.new(variant).can_supply? quantity
        end

        unless valid
          variant = line_item.variant
          display_name = %Q{#{variant.name}}
          display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?
          line_item.errors[:quantity] << Spree.t(:selected_quantity_not_available, :scope => :order_populator, :item => display_name.inspect)
          false
        else
          true
        end
      end


      def validate_order(order)
        item_builder = Spree::Stock::OrderItemBuilder.new(order)

        # group the order's variants. Ex: {324=>3, 1405=>4, 321=>2, 323=>3, 322=>3}
        grouped_variants = item_builder.group_variants

        # remove variant ids, which have allocated inventory units
        # {324=>2, 1405=>3, 321=>2}
        grouped_units = order.inventory_units.where(pending: false).group(:variant_id).count

        grouped_variants = grouped_variants.each do |variant_id, count|
          grouped_variants[variant_id] = grouped_variants[variant_id].to_i - grouped_units[variant_id].to_i
        end.select {|v_id, count| count > 0}

        valids = grouped_variants.map do |variant_id, quantity|
          variant = Spree::Variant.find(variant_id)
          if !Stock::Quantifier.new(variant).can_supply? quantity
            display_name = %Q{#{variant.name}}
            display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?

            out_of_stock_line_item = item_builder.find_by_variant_id(variant_id).last.line_item
            out_of_stock_line_item.errors[:quantity] << Spree.t(:selected_quantity_not_available, :scope => :order_populator, :item => display_name.inspect)

            false
          else
            true
          end
        end

        valids.all?
      end

    end
  end
end