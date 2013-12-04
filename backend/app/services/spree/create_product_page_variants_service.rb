module Spree
  class CreateProductPageVariantsService < Mutations::Command

    required do
      model :product_page, class: 'Spree::ProductPage'
      integer :variant_id
    end

    def execute
      variant = Spree::Variant.find(variant_id)
      ActiveRecord::Base.transaction do
        last_variant = product_page.product_page_variants.
          where(deleted_at: nil).
          where.not(position: nil).
          order('position DESC').
          first
        last_position = last_variant ? last_variant.position : 0
        ppv = Spree::ProductPageVariant.with_deleted.find_or_create_by(
          product_page: product_page,
          variant: variant,
          target_id: product_page.target ? product_page.target.id : nil
        )
        ppv.update_attributes(deleted_at: nil, position: (last_position + 1))
      end
    end
  end
end
