module Spree

  class VariantInStockCacheAdjuster

    attr_reader :variant, :cached_variants

    def initialize(variant, cached_variants={})
      @variant = variant
      @cached_variants = cached_variants
    end

    def perform
      if dynamic_assembly?
        adjust_dynamic_assembly
      elsif static_assembly?
        adjust_static_assembly
      else
        set_in_stock_cache_for_variant
      end
    end

    private

    def set_in_stock_cache_for_variant
      set_in_stock_cache(!variant.can_supply?)
    end

    def static_assembly?
      variant.product.assemblies_parts.any? ||
      variant.assemblies_parts.any?
    end

    def dynamic_assembly?
      !variant.assembly_definition.nil?
    end

    def adjust_static_assembly
      out_of_stock = variant.required_parts.detect do |part|
        part_out_of_stock?(part)
      end
      set_in_stock_cache(out_of_stock)
    end

    def adjust_dynamic_assembly
      out_of_stock = variant.assembly_definition.parts.detect do |part|
        part.required? && part.variants.all? do |part_variant|
          part_out_of_stock?(part_variant)
        end
      end
      set_in_stock_cache(out_of_stock)
    end

    def part_out_of_stock?(part)
      if cached_variants.any? && cached_variant = cached_variants[part]
        !cached_variant.in_stock_cache?
      else
        !part.in_stock_cache?
      end
    end

    def set_in_stock_cache(out_of_stock)
      if out_of_stock
        disable_in_stock_cache
      else
        enable_in_stock_cache
      end
    end

    def disable_in_stock_cache
      if variant.in_stock_cache
        variant.disable_in_stock_cache
        true
      else
        false
      end
    end

    def enable_in_stock_cache
      if !variant.in_stock_cache
        variant.enable_in_stock_cache
        true
      else
        false
      end
    end

  end


  class StockCheckJob

    attr_reader :variant_to_check, :adjusted_variants, :force

    def initialize(variant, force=false)
      @variant_to_check = variant
      @force = force
      @adjusted_variants = Hash.new
    end

    def perform
      variant_in_stock_cache_adjuster(variant_to_check)

      update_assemblies_in_stock_cache

      persist_updates
      rebuild_suite_tab_caches
    end

    private

    def variant_in_stock_cache_adjuster(variant)
      updated = VariantInStockCacheAdjuster.new(variant, adjusted_variants).perform
      add_to_adjusted_variants(variant) if (updated or force)
    end

    def update_assemblies_in_stock_cache
      parts_accumilator = [ variant_to_check ]

      while( parts_accumilator.any? )
        part = parts_accumilator.shift

        static_assemblies = fetch_static_assemblies(part)
        set_in_stock_cache_of_static_assemblies(static_assemblies, part)
        parts_accumilator += static_assemblies

        dynamic_assemblies = fetch_dynamic_assemblies(part)
        set_in_stock_cache_of_dynamic_assemblies(dynamic_assemblies)
        parts_accumilator += dynamic_assemblies.map(&:variant)
      end
    end

    def fetch_static_assemblies(part)
      grouping = Spree::AssembliesPart.where(part_id: part.id, optional: false).group_by(&:assembly_type)
      variant_list = (grouping['Spree::Variant'] ? grouping['Spree::Variant'].map(&:assembly_id) : [])
      product_list = (grouping['Spree::Product'] ? grouping['Spree::Product'].map(&:assembly_id) : [])
      Spree::Variant.where("id IN (?) OR product_id IN (?)", variant_list, product_list)
    end

    def set_in_stock_cache_of_static_assemblies(assemblies, part)
      if part.in_stock_cache
        adjust_static_assemblies(assemblies)
      else
        assemblies.each do |assembly|
          if assembly.in_stock_cache or force
            assembly.disable_in_stock_cache
            add_to_adjusted_variants(assembly)
          end
        end
      end
    end
  
    def add_to_adjusted_variants(variant)
      @adjusted_variants[variant] = variant
    end

    def adjust_static_assemblies(assemblies)
      assemblies.each do |assembly|
        variant_in_stock_cache_adjuster(assembly)
      end
    end

    def fetch_dynamic_assemblies(part)
      asm_def_variants = part.assembly_definition_variants.select do |asm_def_variant|
        asm_def_variant.assembly_definition_part.required?
      end
      asm_def_variants.map(&:assembly_definition_part).map(&:assembly_definition).uniq.compact
    end

    def set_in_stock_cache_of_dynamic_assemblies(assemblies)
      assemblies.each do |assembly|
        variant_in_stock_cache_adjuster(assembly.variant)
      end
    end

    def persist_updates
      adjusted_variants.values.each do |v|
        v.update_column(:in_stock_cache, v.in_stock_cache)
        v.touch
      end
    end

    def rebuild_suite_tab_caches
      products = adjusted_variants.values.map(&:product).flatten.uniq
      products.each do |product|
        rebuild_suite_tab_cache(product)
      end
    end

    def rebuild_suite_tab_cache(product)
      Spree::SuiteTabCacheRebuilder.rebuild_from_product(product)
    end

  end
end
