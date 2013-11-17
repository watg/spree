module Spree
  class CreateProductPageVariantsService < Mutations::Command

    required do
      model :product_page, class: 'Spree::ProductPage'
      integer :variant_id
    end

    def execute
      variant = Spree::Variant.find(variant_id)
      ActiveRecord::Base.transaction do
        product_page.display_variants << variant
      end
    end
  end
end
