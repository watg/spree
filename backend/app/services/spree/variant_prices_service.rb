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
      ActiveRecord::Base.transaction do
        sale_items = in_sale.to_set
        if commit == APPLY_ALL
          master_id = product.master.id.to_s
          master_prices = vp[master_id]
          product.variants_including_master.each do |variant|
            update_prices(master_prices, variant)
            variant.update_attributes(in_sale: sale_items.include?(master_id) )
          end
          product.master.reload
        else
          vp.each do |variant_id, prices|
            variant = Spree::Variant.find(variant_id)
            update_prices(prices, variant)
            variant.update_attributes(in_sale: sale_items.include?(variant_id) )
          end
        end

        product.touch # this is here to invalidate the cache set on taxon through product 
      end
    rescue Exception => e
      Rails.logger.error "[NewVariantService] #{e.message} -- #{e.backtrace}"
      add_error(:variant, :exception, e.message)
    end


  end
end
