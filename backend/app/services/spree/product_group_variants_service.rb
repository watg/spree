module Spree
  class ProductGroupVariantsService < Mutations::Command

    required do
      model :product_group, class: 'Spree::ProductGroup'
      array :variant_ids do
        integer
      end
    end

    def execute
      variants = Spree::Variant.find(variant_ids)
      ActiveRecord::Base.transaction do
        product_group.display_variants = variants
      end
    end

    private
  end
end
