module Spree
  class UpdateProductPageService < Mutations::Command
    required do
      model :product_page, class: 'Spree::ProductPage'
      duck  :details
    end

    def execute
      ActiveRecord::Base.transaction do
        pg_ids = split_params(details[:product_group_ids])
        deleted_product_group_list = product_group_to_remove(pg_ids)

        product_page.name               = details[:name]
        product_page.title              = details[:title]
        product_page.permalink          = details[:permalink]
        product_page.target_id          = details[:target_id]
        product_page.accessories        = details[:accessories]
        product_page.kit_id             = details[:kit_id]
        product_page.product_group_ids  = pg_ids
        product_page.tags               = find_tags(details[:tags] || [])

        product_page.tabs_attributes    = details[:tabs_attributes]
        product_page.save!

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

    def find_tags(tag_ids)
      ids = tag_ids.map(&:to_i).select {|e| e > 0 }
      Spree::Tag.find(ids)
    end
  end
end
