module Spree
  class DisplayableVariantsService < Mutations::Command

    required do
      integer :product_id
      array   :variant_ids
    end
    
    def execute
      product = Spree::Product.find(product_id)
      ActiveRecord::Base.transaction do
        update_displayable_variants(product,variant_ids)
      end
    rescue Exception => error
      add_error(:variant, :exception, error.message)
    end


    private

    def update_displayable_variants( product, variant_ids )
      current_ids = Spree::DisplayableVariant.where(product_id: product.id).uniq.pluck(:variant_id)

      variants_to_add(current_ids, variant_ids).each do |variant_id|
        all_taxons( product.taxons ).each do |taxon|
          Spree::DisplayableVariant.create!(product_id: product.id, variant_id: variant_id, taxon_id: taxon.id)
        end
      end

      to_remove = variants_to_remove(current_ids, variant_ids)
      Spree::DisplayableVariant.destroy_all(product_id: product.id, variant_id: to_remove) unless to_remove.blank?
    end

    def all_taxons(taxons)
      taxons.map do |t|
        t.self_and_parents
      end.flatten
    end

    def variants_to_remove(current_ids, variant_ids)
      variant_ids ||= []
      current_ids - variant_ids.map(&:to_i)
    end

    def variants_to_add(current_ids, variant_ids)
      variant_ids ||= []
      variant_ids.map(&:to_i) - current_ids
    end
  end
end
