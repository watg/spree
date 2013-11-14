module Spree
  module Admin
    class ProductPageVariantsController < ResourceController
      def index
        @product_page = load_product_page

        @product_page_variants = @product_page.display_variants.group_by { |v| v.product.product_type }
        @available_variants = @product_page.available_variants.group_by { |v| v.product.product_type }
        @product_types = (@available_variants.keys + @product_page_variants.keys).uniq.sort
      end

      def create
        product_page = load_product_page
        outcome = Spree::ProductPageVariantsService.run(
          product_page: product_page,
          variant_ids: params["variant_ids"]
        )
        if !outcome.success?
          flash[:error] = outcome.errors.message_list.join('<br/>')
        end
        redirect_to admin_product_page_product_page_variants_url(product_page)
      end

      private

      def load_product_page
        Spree::ProductPage.find(params[:product_page_id])
      end
    end
  end
end
