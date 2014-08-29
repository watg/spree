module Spree
  module Stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        order = line_item.order

        # {324=>2, 1405=>3, 321=>2, 323=>2, 322=>3}
        grouped_units = order.inventory_units.group(:variant_id).count
        required = group_variants(order, line_item)

        variants_to_check = required.each do |v, count|
          required[v] = required[v].to_i - grouped_units[v].to_i
        end.select {|v, count| count > 0}

        valid = variants_to_check.all? do |variant_id, quantity|
          variant = Spree::Variant.find(variant_id)
          Stock::Quantifier.new(variant).can_supply? quantity
        end

        unless valid
          variant = line_item.variant
          display_name = %Q{#{variant.name}}
          display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?
          line_item.errors[:quantity] << Spree.t(:selected_quantity_not_available, :scope => :order_populator, :item => display_name.inspect)
        end
        true
      end

    private

      def group_variants(order, line_item)
        # uniq would break other tests, which depend on the order.line_items association
        (order.line_items.without(line_item).to_a + [line_item]).inject({}) do |hash, line|

          unless line.parts.any?
            hash[line.variant_id] ||= 0
            hash[line.variant_id] += line.quantity
          end

          line.parts.each do |part|
            next if part.container?
            hash[part.variant_id] ||= 0
            hash[part.variant_id] += part.quantity * line.quantity
          end

          hash
        end
      end

    end
  end
end
