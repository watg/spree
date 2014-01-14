module Spree
  class StockCheckJob < Struct.new(:stock_item)
    def perform
      if stock_item.variant.assemblies.first
        assembly_list_that_contains_that_variant = Spree::AssembliesPart.where(part_id: stock_item.variant.id, optional: false).reorder('count').group_by(&:count)
        assembly_list_that_contains_that_variant.each {|count, assemblies|  update_assembly(count, assemblies) }
      else
        result = Spree::Stock::Quantifier.new(stock_item.variant).can_supply?(1)
        stock_item.variant.update_attributes(in_stock_cache: result)
      end
    end

    private
    def update_assembly(count, assembly_list)
      result = Spree::Stock::Quantifier.new(stock_item.variant).can_supply?(count)
      assembly_list.each do |e|
        list = (e.assembly_type == 'Spree::Variant' ? [e.assembly] : Spree::Variant.where(product_id: e.assembly_id) ).compact
        list.each {|obj| obj.update_attributes(in_stock_cache: result) }
      end
    end
  end
end
