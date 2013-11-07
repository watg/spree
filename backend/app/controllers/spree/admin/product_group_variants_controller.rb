module Spree
  module Admin
    class ProductGroupVariantsController < ResourceController
      def index
        @product_group = load_product_group

        @product_group_variants = @product_group.display_variants.group_by { |v| v.product.product_type }
        @available_variants = @product_group.available_variants.group_by { |v| v.product.product_type }
        @product_types = (@available_variants.keys + @product_group_variants.keys).uniq.sort
      end

      def create
        product_group = load_product_group
        outcome = Spree::ProductGroupVariantsService.run(
          product_group: product_group,
          variant_ids: params["variant_ids"]
        )
        if !outcome.success?
          flash[:error] = outcome.errors.message_list.join('<br/>')
        end
        redirect_to admin_product_group_product_group_variants_url(product_group)
      end

      private

      def load_product_group
        Spree::ProductGroup.find(params[:product_group_id])
      end
    end
  end
end
