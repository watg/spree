module Spree
 StockCheckJob = Struct.new(:stock_item) do
    def perform
      variant_in_stock = Spree::Stock::Quantifier.new(stock_item.variant).can_supply?(1)
      stock_item.variant.update_attributes(in_stock_cache: variant_in_stock)

      if stock_item.variant.assemblies.first
        if variant_in_stock
          check_stock_for_kits_using_this_variant(stock_item.variant)
        else
          put_all_kits_using_this_variant_out_of_stock(stock_item.variant)
        end
      end
    end

    private
    def put_all_kits_using_this_variant_out_of_stock(part)
      variant_ids = list_of_kit_variants_using(part).map(&:id)
      Spree::Variant.where(id: variant_ids).update_all(in_stock_cache: false, updated_at: Time.now) if variant_ids
    end

    def check_stock_for_kits_using_this_variant(part)
      list_of_kit_variants_using(part, false).each do |kit_variant|
        kit_in_stock = Spree::Stock::Quantifier.new(kit_variant).can_supply?(1)
        kit_variant.update_attributes(in_stock_cache: kit_in_stock)
      end
    end

    def list_of_kit_variants_using(part, in_stock_cache=true)
      grouping = Spree::AssembliesPart.where(part_id: part.id, optional: false).group_by(&:assembly_type)
      variant_list = (grouping['Spree::Variant'] ? grouping['Spree::Variant'].map(&:assembly_id) : [])
      product_list = (grouping['Spree::Product'] ? grouping['Spree::Product'].map(&:assembly_id) : [])
      Spree::Variant.where("id IN (?) OR product_id IN (?) AND in_stock_cache = ?", variant_list, product_list, in_stock_cache)
    end

  end
end
