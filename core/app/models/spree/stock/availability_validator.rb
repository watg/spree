module Spree
  module Stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)
        shipment = line_item.target_shipment
        if shipment
          # those units should be linked to line_item 
          units = shipment.inventory_units_for(line_item.variant)
          return if units.count > line_item.quantity
          adjusted_quantity = line_item.quantity - units.count
          old_quantity = line_item.quantity
          line_item.quantity = adjusted_quantity
        end

        result = Spree::Stock::Quantifier.can_supply_order?(line_item.order, line_item)

        line_item.quantity = old_quantity if old_quantity

        line_item_errors = result[:errors].select {|err| err[:line_item_id] == line_item.id}

        unless line_item_errors.blank?
          variant = line_item.variant
          display_name = %Q{#{variant.name}}
          display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?

          line_item.errors[:quantity] << Spree.t(:selected_quantity_not_available, :scope => :order_populator, :item => display_name.inspect)
        end
      end

    end

  end
end
