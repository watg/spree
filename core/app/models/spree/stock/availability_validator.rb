module Spree
  module Stock
    class AvailabilityValidator < ActiveModel::Validator
      def validate(line_item)

        # Do not validate if we are reducing the quantity
        oqtty, nqtty = old_and_new_quantities(line_item)
        return if oqtty > nqtty

        shipment = line_item.target_shipment
        if shipment
          validate_line_item_on_completed_order(line_item, shipment, oqtty, nqtty)
        else
          validate_line_item(line_item)
        end
      end

      private

      def old_and_new_quantities(line_item)
        (line_item.changes['quantity'] ? line_item.changes['quantity'].map(&:to_i) : [0,0])
      end

      def validate_line_item_on_completed_order(line_item, shipment, oqtty, nqtty)
        units = shipment.inventory_units_for(line_item.variant)
        return if units.count > line_item.quantity  # quantity on line item is decremented

        if oqtty < nqtty
          increased_quantity = nqtty - oqtty

          variant_quantity_grouping = get_variant_quantity_grouping(line_item, increased_quantity)

          variant_quantity_grouping_with_stock = eager_load_stock_items( variant_quantity_grouping )

          variant_quantity_grouping_with_stock.map do |variant, quantity|
            in_stock = Spree::Stock::Quantifier.new(variant, variant.stock_items).can_supply?(quantity)
            unless in_stock
              display_name = %Q{#{variant.name}}
              display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?
              line_item.errors[:quantity] << Spree.t(:selected_quantity_not_available, :scope => :order_populator, :item => display_name.inspect)
            end
          end
        end
      end

      def eager_load_stock_items( variant_quantity_grouping )
        variants_with_stock = Spree::Variant.includes(:stock_items =>[:stock_location]).
          includes(:product).
          where( Spree::StockLocation.table_name =>{ :active => true} ).find(variant_quantity_grouping.keys)

        variants_with_stock.inject({}) do |hash,v| 
          hash[v] = variant_quantity_grouping[v.id]
          hash
        end
      end

      def get_variant_quantity_grouping(line_item, li_quantity)
        item_list  = [{
          variant_id: line_item.variant_id,
          quantity:   li_quantity
        }]

        line_item.line_item_parts.each do |pa|
          item_list << {
            variant_id:   pa.variant_id,
            quantity:     pa.quantity * li_quantity
          }
        end

        item_list.reduce({}) {|hsh, c|
          k = c[:variant_id]
          hsh[k] ||= 0; hsh[k] += c[:quantity]
          hsh}
      end

      def validate_line_item(line_item)
        result = Spree::Stock::Quantifier.can_supply_order?(line_item.order, line_item)

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
