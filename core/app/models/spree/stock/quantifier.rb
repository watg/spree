module Spree
  module Stock
    class Quantifier

      class << self
        def new(variant)
          instance = (variant.kind_of?(Spree::Variant) ? variant : Spree::Variant.find(variant))
          klass_name = (has_parts?(instance) ? 'AssemblyQuantifier' : 'SimpleQuantifier')
          klass = "Spree::Stock::#{klass_name}".constantize

          klass.new(instance)
        end

        def has_parts?(variant)
          variant.product.can_have_parts?
        end

        def can_supply_order?(order, desired_line_item=nil)
          line_item_to_record = lambda do |li, lio|
            ([li] + [lio]).flatten.compact.map do |line_item|
              li_id = line_item.kind_of?(Spree::LineItem) ? line_item.id : line_item.line_item.id

              { line_item_id: li_id, 
                variant_id: line_item.variant_id, 
                quantity: line_item.quantity }
            end
          end

          a = line_item_to_record[order.line_items,  order.line_items.map(&:line_item_options).flatten]
          b = if desired_line_item && desired_line_item.new_record?
                line_item_to_record[desired_line_item, (desired_line_item ? desired_line_item.line_item_options : [])]
              else
                # nothing to do because desired_line_item is already
                # part of the order
                [] 
              end

          variant_quantity_grouping = (a + b).reduce({}) {|hsh, c|
                             k = c[:variant_id]
                             hsh[k] ||= 0; hsh[k] += c[:quantity]
                             hsh}
          errors = []
          stock_check = variant_quantity_grouping.map {|variant_id, quantity|
                            variant = Spree::Variant.find(variant_id)
                            in_stock = Spree::Stock::Quantifier.new(variant).can_supply?(quantity)
                            errors << add_error(variant, a) unless in_stock
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
