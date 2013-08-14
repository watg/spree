module Spree
  class DisplayableVariantsService < Struct.new(:controller)
    def perform(product_id, variant_ids)
      product = Spree::Product.find(product_id)
      current_ids = Spree::DisplayableVariant.where(product_id: product.id).uniq.pluck(:variant_id)
      
      variants_to_add(current_ids, variant_ids).each do |variant_id|
        product.taxons.each do |taxon|
          Spree::DisplayableVariant.create(product_id: product_id, variant_id: variant_id, taxon_id: taxon.id)
        end
      end

      to_remove = variants_to_remove(current_ids, variant_ids)
      Spree::DisplayableVariant.destroy_all(product_id: product_id, variant_id: to_remove) unless to_remove.blank?
      
      controller.send(:update_success, product)
 
    rescue Exception => error
      
      controller.send(:update_failure, product, error)
    end


    private
    def variants_to_remove(current_ids, variant_ids=[])
      current_ids - variant_ids.map(&:to_i)
    end

    def variants_to_add(current_ids, variant_ids=[])
      variant_ids.map(&:to_i) - current_ids
    end
  end
end
