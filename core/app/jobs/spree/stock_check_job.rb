module Spree
  StockCheckJob = Struct.new(:variant) do
    def perform

      variant_in_stock = check_stock(variant)

      # for old kits
      if variant.assemblies.any?
        if variant_in_stock
          check_stock_for_kits_using_this_variant(variant)
        else
          put_all_kits_using_this_variant_out_of_stock(variant)
        end
      end

    end

    private

    def check_stock(variant)
      variant_in_stock = Spree::Stock::Quantifier.new(variant).can_supply?(1)
      if variant.in_stock_cache != variant_in_stock
        variant.update_attributes(in_stock_cache: variant_in_stock)
      end
      variant_in_stock
    end

    def put_all_kits_using_this_variant_out_of_stock(part)
      variant_ids = list_of_kit_variants_using(part).map(&:id)
      Spree::Variant.where(id: variant_ids).update_all(in_stock_cache: false, updated_at: Time.now) if variant_ids
    end

    def check_stock_for_kits_using_this_variant(part)
      list_of_kit_variants_using(part, false).each do |kit_variant|
        out_of_stock_parts = kit_variant.required_parts_for_display.select do |p|
           !Spree::Stock::Quantifier.new(p).can_supply?(1)
        end

        if out_of_stock_parts.any?
          kit_variant.update_attributes(in_stock_cache: false)
        else
          kit_variant.update_attributes(in_stock_cache: true)
        end

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
