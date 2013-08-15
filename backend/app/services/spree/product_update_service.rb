module Spree
  class ProductUpdateService
    attr_reader :controller
    def initialize(controller=nil)
      @controller = controller
    end
  
    def perform(product, params)
      params[:taxon_ids] = assign_taxons(product, params[:taxon_ids])
      update_details(product, params)
    end
  
    def update_details(product, params)
      params[:option_type_ids] = assign_option_types(product, params[:option_type_ids])
      update_before(params)
  
      if product.update_attributes(params)
        controller.send(:update_success,product)
      else
        controller.send(:update_failed,product)
      end
    end
  
    def assign_option_types(product, params=nil)
      params.blank?  ? [] : params.split(',').map(&:to_i)
    end
  
  
    def assign_taxons(product, params=nil)
      params  = (params.blank? ? [] : params.split(',').map(&:to_i))

      variant_ids = product.variants.map(&:id)

      taxons_to_add(product, params).map do |t|
        variant_ids.map do |variant_id|
          Spree::DisplayableVariant.create(product_id: product.id, taxon_id: t, variant_id: variant_id)
        end
      end.flatten

      to_remove = taxons_to_remove(product, params)
      Spree::DisplayableVariant.destroy_all(product_id: product.id, taxon_id: to_remove) unless to_remove.blank?
       
      params
     end

    
    private
    def update_before(params)
      # note: we only reset the product properties if we're receiving a post from the form on that tab
      return unless params[:clear_product_properties]
      params ||= {}
    end

    def taxons_to_remove(product, params=[])
      taxon_ids = (product.taxons.blank? ? [] : product.taxons.map(&:id))
      taxon_ids - params
    end
    
    def taxons_to_add(product, params=[])
      taxon_ids = (product.taxons.blank? ? [] : product.taxons.map(&:id))
      params - taxon_ids
    end

  end
end
