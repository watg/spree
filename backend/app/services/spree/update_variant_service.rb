module Spree
  class UpdateVariantService < ActiveInteraction::Base
    include ServiceTrait::Prices
    include ServiceTrait::StockThresholds

    model :variant, class: 'Spree::Variant'
    hash :details, strip: false
    hash :prices, strip: false, default: nil
    hash :stock_thresholds, strip: false, default: nil

    def execute
      validate_prices(prices) if prices
      unless errors.any?

        tags = details.delete(:tags)
        target_ids = details.delete(:target_ids)

        # Set the supplier, but only on a create and not an update
        supplier_id = details.delete(:supplier_id)

        if variant.new_record?
          supplier = compose(Spree::StockItemSupplierService, variant: variant, supplier_id: supplier_id.to_s)
          variant.supplier = supplier
        end

        set_product_type_defaults(variant)

        variant.update_attributes(details)
        return merge_errors_onto_base(variant.errors) if variant.invalid?

        update_tags(variant, split_params(tags).map(&:to_i) ) if tags
        assign_targets(variant, split_params(target_ids).map(&:to_i) ) if target_ids
        update_prices(prices, variant) if prices

        update_stock_thresholds(stock_thresholds, variant) if stock_thresholds

        variant
      end
    end

    private

    # TODO: this should be maybe in the product type?
    def set_product_type_defaults(variant)
      if variant.product.product_type.is_assembly?
        variant.in_stock_cache = true
        variant.track_inventory = false
      end
    end

    # Allows us to use the price trait
    def add_error(first, _second, message)
      errors.add(first, message)
    end

    def update_tags(variant, tag_ids)
      tags = tag_ids.map do |tag_id|
        Spree::Tag.find(tag_id)
      end
      variant.tags = tags
    end

    def assign_targets(variant, ids)
      variant.variant_targets.where.not(target_id: ids).delete_all
      ids.each do |id|
        if !variant.variant_targets.find_by(target_id: id)
          variant.targets << Spree::Target.find_by(id: id)
        end
      end
    end

    def split_params(input)
      input.blank? ? [] : input.split(',')
    end

  end
end
