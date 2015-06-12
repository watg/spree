module Spree
  # Set the in stock cache variable on the master / variant based on whether the variant or
  # the variant parts that make up the kit are in stock
  class VariantInStockCacheAdjuster
    attr_reader :variant, :cached_variants

    def initialize(variant, cached_variants = {})
      @variant = variant
      @cached_variants = cached_variants
    end

    def perform
      if dynamic_assembly?
        adjust_dynamic_assembly
      elsif static_assembly?
        adjust_static_assembly
      else
        adjust_in_stock_cache_for_variant
      end
    end

    private

    def adjust_in_stock_cache_for_variant
      adjust_in_stock_cache(!variant.can_supply?)
    end

    def static_assembly?
      variant.product.static_assemblies_parts.any? ||
        variant.static_assemblies_parts.any?
    end

    def configurations
      variant.product.configurations
    end

    def dynamic_assembly?
      configurations.any?
    end

    def adjust_static_assembly
      out_of_stock = variant.required_parts.detect do |part|
        part_out_of_stock?(part)
      end
      adjust_in_stock_cache(out_of_stock)
    end

    def adjust_dynamic_assembly
      adjust_in_stock_cache(out_of_stock)
    end

    def out_of_stock
      required_configurations.detect do |config|
        config.variants.all?(&method(:part_out_of_stock?))
      end
    end

    def required_configurations
      configurations.select(&:required?)
    end

    def part_out_of_stock?(part)
      if cached_variants[part]
        !cached_variants[part].in_stock_cache?
      else
        !part.in_stock_cache?
      end
    end

    def adjust_in_stock_cache(out_of_stock)
      if out_of_stock
        disable_in_stock_cache
      else
        enable_in_stock_cache
      end
    end

    def disable_in_stock_cache
      if variant.in_stock_cache
        variant.update(in_stock_cache: false)
        true
      else
        false
      end
    end

    def enable_in_stock_cache
      if !variant.in_stock_cache
        variant.update(in_stock_cache: true)
        true
      else
        false
      end
    end
  end

  # Checks a variant and ajdusts it's in_stock_cache value, and also adjusts any upstream variants
  # which it makes up as part of a kit
  class StockCheckJob
    attr_reader :variant_to_check, :adjusted_variants, :force

    def initialize(variant, force = false)
      @variant_to_check = variant
      @force = force
      @adjusted_variants = {}
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
      add_to_adjusted_variants(variant) if updated || force
    end

    def update_assemblies_in_stock_cache
      obj_accumilator = [variant_to_check]

      while obj_accumilator.any?
        obj = obj_accumilator.shift
        static_assemblies = fetch_static_assemblies(obj)
        adjust_in_stock_cache_of_static_assemblies(static_assemblies, obj)
        obj_accumilator += static_assemblies

        dynamic_master_variants = fetch_dynamic_master_variants(obj)
        adjust_in_stock_cache_for_dynamic_master_variants(dynamic_master_variants)

        obj_accumilator += dynamic_master_variants
      end
    end

    def fetch_static_assemblies(part)
      grouped_assembly_parts =
        Spree::StaticAssembliesPart.where(part_id: part.id, optional: false)
        .group_by(&:assembly_type)

      variant_assembly_parts = grouped_assembly_parts["Spree::Variant"]
      variant_list = variant_assembly_parts ? variant_assembly_parts.map(&:assembly_id) : []

      product_assembly_parts = grouped_assembly_parts["Spree::Product"]
      product_list = product_assembly_parts ? product_assembly_parts.map(&:assembly_id) : []

      Spree::Variant.where("id IN (?) OR product_id IN (?)", variant_list, product_list)
    end

    def adjust_in_stock_cache_of_static_assemblies(assemblies, part)
      if part.in_stock_cache
        adjust_static_assemblies(assemblies)
      else
        assemblies.each do |assembly|
          if assembly.in_stock_cache || force
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

    def fetch_dynamic_master_variants(obj)
      obj.product.products.map(&:master)
    end

    def adjust_in_stock_cache_for_dynamic_master_variants(variants)
      variants.each(&method(:variant_in_stock_cache_adjuster))
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
