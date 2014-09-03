module Spree
  class UpdateVariantService < ActiveInteraction::Base
    include ServiceTrait::Prices

    model :variant, class: 'Spree::Variant'
    hash :details, strip: false
    hash :prices, strip: false, default: nil

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

        variant.update_attributes!(details)

        update_tags(variant, split_params(tags).map(&:to_i) ) if tags
        assign_targets(variant, split_params(target_ids).map(&:to_i) ) if target_ids
        update_prices(prices, variant) if prices

        variant
      end
    end

    private

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
      target_list = targets_to_remove(variant, ids)
      variant.variant_targets.where.not(target_id: ids).delete_all
      ids.each do |id|
        if !variant.variant_targets.find_by(target_id: id)
          variant.targets << Spree::Target.find_by(id: id)
        end
      end
      remove_targeted_variant_from_product_pages(variant, target_list)
    end

    def split_params(input)
      input.blank? ? [] : input.split(',')
    end

    def targets_to_remove(variant, list)
      list ||= []
      target_ids = (variant.targets.blank? ? [] : variant.targets.map(&:id))
      (target_ids - list)
    end

    def remove_targeted_variant_from_product_pages(variant, target_list)
      Spree::ProductPageVariant.where(variant_id: variant.id, target_id: target_list).update_all(deleted_at: Time.now)
    end
  end
end
