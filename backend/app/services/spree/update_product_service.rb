module Spree
  class UpdateProductService < Mutations::Command
    include ServiceTrait::Prices
    required do
      model :product, class: 'Spree::Product'
      duck  :details
      duck  :prices, nils: true
    end

    def execute
      visible_option_type_ids = details.delete(:visible_option_type_ids)
      ActiveRecord::Base.transaction do
        assign_taxons(product, details[:taxon_ids])               unless details.has_key?(:product_properties_attributes)
        update_details(product, details.dup)
        update_prices(prices.dup, product.master)                 if prices
        option_type_visibility(product, visible_option_type_ids)  unless details.has_key?(:product_properties_attributes)
      end
    rescue Exception => e
      Rails.logger.error "[ProductUpdateService] #{e.message} -- #{e.backtrace}"
      add_error(:product_update, :exception, e.message)
    end

    def update_details(product, product_params)
      product_params[:option_type_ids] = split_params(product_params[:option_type_ids])
      product_params[:taxon_ids] = split_params(product_params[:taxon_ids])

      update_before(product_params)

      update_outcome = product.update_attributes(product_params)
      if update_outcome == false or product.errors.any?
        add_error(:product, :details, product.errors.full_messages.join(', '))
      end
    end

    def split_params(input=nil)
      input.blank? ? [] : input.split(',').map(&:to_i)
    end

    def assign_taxons(product, list='')
      dv_params = split_params(list)
      variant_ids = current_displayable_variants(product)

      taxons_to_add(product, dv_params).map do |t|
        variant_ids.map do |variant_id|
          Spree::DisplayableVariant.create!(product_id: product.id, taxon_id: t, variant_id: variant_id)
        end
      end.flatten

      to_remove = taxons_to_remove(product, dv_params)
      Spree::DisplayableVariant.destroy_all(product_id: product.id, taxon_id: to_remove) unless to_remove.blank?

      dv_params
    end

    def option_type_visibility(product, visible_option_type_ids)
      list = split_params(visible_option_type_ids)
      option_type_ids = product.option_types.map(&:id)

      reset_visible_option_types(product.id, (option_type_ids - list))
      update_visible_option_types(product.id, list)
    end

    private
    def update_visible_option_types(p_id, list)
      list.each {|ot_id|
        if pot = Spree::ProductOptionType.where(product_id: p_id, option_type_id: ot_id).first
          make_visible(pot)
        end
      }
    end
    def reset_visible_option_types(product_id, ids_to_reset)
      Spree::ProductOptionType.where(product_id: product_id, option_type_id: ids_to_reset).update_all(visible: false)
    end

    def make_visible(product_option_type)
      product_option_type.update_attributes(visible: true)
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

    def taxons_to_remove(product, list)
      list ||= []
      taxon_ids = (product.taxons.blank? ? [] : product.taxons.map(&:id))
      all_taxons(taxon_ids - list)
    end

    def taxons_to_add(product, list)
      list ||= []
      taxon_ids = (product.taxons.blank? ? [] : product.taxons.map(&:id))
      all_taxons( list - taxon_ids )
    end

  end
end
