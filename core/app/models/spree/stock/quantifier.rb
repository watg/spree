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
          record = lambda {|line_item| {variant_id: line_item.variant_id, quantity: line_item.quantity}}
          line_item_to_record = lambda {|li, lio|([li] + [lio]).flatten.compact.map(&record) }

          a = line_item_to_record[order.line_items,  order.line_items.map(&:line_item_options).flatten]
          b = line_item_to_record[desired_line_item, (desired_line_item ? desired_line_item.line_item_options : [])]

          variant_quantity_grouping = (a + b).reduce({}) {|hsh, c|
                             k = c[:variant_id]
                             hsh[k] ||= 0; hsh[k] += c[:quantity]
                             hsh}
          errors = []
          stock_check = variant_quantity_grouping.map {|variant_id, quantity|
                            variant = Spree::Variant.find(variant_id)
                            in_stock = Spree::Stock::Quantifier.new(variant).can_supply?(quantity)
                            errors << Spree.t(:out_of_stock, :scope => :order_populator, :item => %Q{#{variant.name} #{variant.options_text}}.inspect) unless in_stock
                            in_stock}
          result = stock_check.reduce(true) {|can_supply,c| can_supply && c}

          {in_stock: result, errors: errors}
        end
      end

    end
  end
end
