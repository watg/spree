module Spree
  class UpdateVariantService < Mutations::Command
    include ServiceTrait::Prices
    required do
      duck :variant#, class: 'Spree::Variant'
    end

    optional do
      hash :details do
        optional do
          string :sku
          array :option_value_ids do
            string
          end
          string :tags, empty: true
          string :target_ids, empty: true

          float :height
          float :depth
          float :width
          float :weight
          string :label, nils: true, empty: true
          integer :part_id

          string :track_inventory
        end

      end

      hash :prices do
        optional do
          duck :normal
          duck :normal_sale
        end

        optional do
          duck :part
          duck :part_sale
        end
      end
    end

    def execute
      validate_prices(prices) if prices
      unless has_errors? 
        ActiveRecord::Base.transaction do

          if prices
            update_prices(prices, variant)
          end

          if tags = details.delete(:tags)
            update_tags(variant, split_params(tags).map(&:to_i) )
          end

          if target_ids = details.delete(:target_ids)
            assign_targets(variant, split_params(target_ids).map(&:to_i) )
          end

          variant.update_attributes!(details)

          variant
        end
      end
    rescue Exception => e
      puts e.backtrace
      Rails.logger.error "[NewVariantService] #{e.message} -- #{e.backtrace}"
      add_error(:variant, :exception, e.message)
    end

    private

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
        variant.variant_targets.find_or_create_by(target_id: id)
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
