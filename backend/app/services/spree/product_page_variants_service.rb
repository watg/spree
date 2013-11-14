module Spree
  class ProductPageVariantsService < Mutations::Command

    required do
      model :product_page, class: 'Spree::ProductPage'
      array :variant_ids do
        integer
      end
    end

    def execute
      variants = Spree::Variant.find(variant_ids)
      ActiveRecord::Base.transaction do
        product_page.display_variants = variants
      end
    end

    private
  end
end
