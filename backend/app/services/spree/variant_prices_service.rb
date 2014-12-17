module Spree
  class VariantPricesService < Mutations::Command 
    include ServiceTrait::Prices

    APPLY_ALL = 'apply_all'

    required do
      duck   :vp
      model  :product, class: 'Spree::Product'
      array  :in_sale
      string :commit, nils: true
    end

    def execute
      if commit == APPLY_ALL
          master_id = product.master.id.to_s
          validate_prices(vp[master_id])
      else
        vp.each do |_variant_id, prices|
          validate_prices(prices)
        end
      end

      unless has_errors? 
        update_pricing(in_sale, commit, product, vp)
        Spree::SuiteTabCacheRebuilder.rebuild_from_product_async(product)
      end
    rescue Exception => e
      Rails.logger.error "[NewVariantService] #{e.message} -- #{e.backtrace}"
      add_error(:variant, :exception, e.message)
    end

    private

    def update_pricing(in_sale, commit, product, vp)
      ActiveRecord::Base.transaction do
        sale_items = in_sale.to_set
        if commit == APPLY_ALL
          master_id = product.master.id.to_s
          master_prices = vp[master_id]
          product.variants_including_master.each do |variant|
            update_prices(master_prices, variant)
            variant.update_attributes!(in_sale: sale_items.include?(master_id) )
          end
          product.master.reload
        else
          vp.each do |variant_id, prices|
            variant = Spree::Variant.find(variant_id)
            update_prices(prices, variant)
            variant.update_attributes!(in_sale: sale_items.include?(variant_id) )
          end
        end
        product.touch # this is here to invalidate the cache set on taxon through product 
      end
    end

  end
end
