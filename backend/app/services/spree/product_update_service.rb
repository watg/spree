module Spree
  class ProductUpdateService
    attr_reader :controller
    def initialize(controller=nil)
      @controller = controller
    end
  
    def perform(product, params)
      visible_option_type_ids = params.delete(:visible_option_type_ids)

      ActiveRecord::Base.transaction do 
        assign_taxons(product, params[:taxon_ids])
        update_details(product, params.dup)
        option_type_visibility(product, visible_option_type_ids)
      end
    rescue Exception => e
      Rails.logger.error "[ProductUpdateService] #{e.message} -- #{e.backtrace}"
      controller.send(:update_failed,product, e.message)
    end
  
    def update_details(product, params)
      params[:option_type_ids] = split_params(params[:option_type_ids])
      params[:taxon_ids] = split_params(params[:taxon_ids])

      update_before(params)
  
      if product.update_attributes(params)
        controller.send(:update_success,product)
      else
        controller.send(:update_failed,product)
      end
    end
  
    def split_params(params=nil)
      params.blank?  ? [] : params.split(',').map(&:to_i)
    end  
  
    def assign_taxons(product, list='')
      params = split_params(list)
      
      variant_ids = current_displayable_variants(product)

      taxons_to_add(product, params).map do |t|
        variant_ids.map do |variant_id|
          Spree::DisplayableVariant.create!(product_id: product.id, taxon_id: t, variant_id: variant_id)
        end
      end.flatten

      to_remove = taxons_to_remove(product, params)
      Spree::DisplayableVariant.destroy_all(product_id: product.id, taxon_id: to_remove) unless to_remove.blank?
       
      params
    end

    def option_type_visibility(product, visible_option_type_ids)
      list = split_params(visible_option_type_ids)
      option_type_ids = product.option_types.map(&:id)
      
      to_reset = option_type_ids - list
      reset_visible_option_types(product.id, to_reset)

      selection_to_update = list - option_type_ids
      to_update = selection_to_update.map {|e| e if option_type.include?(e)}.compact
      update_visible_option_types(product.id, to_update)
    end
    
    private
    def update_visible_option_types(p_id, list)
      list.each {|ot_id|
        pot = Spree::ProductOptionType.where(product_id: p_id, option_type_id: ot_id).first
        if pot
          pot.update_attributes(visible: true)
        else
          Spree::ProductOptionType.create(product_id: p_id, option_type_id: ot_id, visible: true)
        end
      }
    end
    def reset_visible_option_types(product_id, ids_to_reset)
      Spree::ProductOptionType.where(product_id: product_id, option_type_id: ids_to_reset).update_all(visible: false)
    end
    def update_before(params)
      # note: we only reset the product properties if we're receiving a post from the form on that tab
      return unless params[:clear_product_properties]
      params ||= {}
    end

    def current_displayable_variants(product)
      Spree::DisplayableVariant.where(product_id: product.id).uniq.pluck(:variant_id)
    end

    def all_taxons(taxons_ids)
      taxons = Spree::Taxon.find(taxons_ids)
        taxons.map do |t|
          t.self_and_parents.map(&:id)
        end.flatten
    end

    def taxons_to_remove(product, params)
      params ||= []
      taxon_ids = (product.taxons.blank? ? [] : product.taxons.map(&:id))
      all_taxons(taxon_ids - params)
    end
    
    def taxons_to_add(product, params)
      params ||= []
      taxon_ids = (product.taxons.blank? ? [] : product.taxons.map(&:id))
      all_taxons( params - taxon_ids )
    end

  end
end
