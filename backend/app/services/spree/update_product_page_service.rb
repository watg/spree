module Spree
  class UpdateProductPageService < Mutations::Command
    required do
      model :product_page, class: 'Spree::ProductPage'
      duck  :details
    end

    def execute
      ActiveRecord::Base.transaction do
        pg_ids = split_params(details.delete(:product_group_ids))
        details[:product_group_ids] = pg_ids
        details[:tag_ids] = details.delete(:tags) || [] 
        deleted_product_group_list = product_group_to_remove(pg_ids)

        product_page.update_attributes!(details)

        update_product_page_variants(deleted_product_group_list)
      end
    rescue Exception => e
      puts "[ProductPageUpdateService] #{e.message} -- #{e.backtrace}"
      Rails.logger.error "[ProductPageUpdateService] #{e.message} -- #{e.backtrace}"
      add_error(:product_update, :exception, e.message)
    end

    private
    def update_product_page_variants(removed_pg_list)
      variant_ids = Spree::Variant.
        select('spree_variants.id').
        joins(:product).
        joins('LEFT OUTER JOIN spree_product_groups ON spree_product_groups.id = spree_products.product_group_id').
        where("spree_product_groups.id IN (?)", removed_pg_list).
        map(&:id)

      Spree::ProductPageVariant.where(product_page: product_page, variant_id: variant_ids).delete_all
    end

    def product_group_to_remove(list)
      list ||= []
      pg_ids = (product_page.product_groups.blank? ? [] : product_page.product_groups.map(&:id))
      (pg_ids - list)
    end

    def split_params(input=nil)
      input.blank? ? [] : input.split(',').map(&:to_i)
    end

  end
end
