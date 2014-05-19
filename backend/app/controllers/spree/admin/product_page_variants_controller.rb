module Spree
  module Admin
    class ProductPageVariantsController < BaseController
      def index
        @product_page = load_product_page

        @displayed_variants = @product_page.displayed_variants
        @available_variants = @product_page.available_variants
      end

      def update_positions
        product_page = load_product_page
        params[:positions].each_pair do |id, pos|
          v = product_page.product_page_variants.where(variant_id: id).first
          v.update_attributes(position: pos)
        end
        render nothing: true
      end

      def create
        product_page = load_product_page
        @variant_id = params["variant_id"]
        outcome = Spree::CreateProductPageVariantsService.run(
          product_page: product_page,
          variant_id: @variant_id
        )
        if outcome.success?
          respond_to do |format|
            format.js
          end
        else
          respond_to do |format|
            format.js {
              errors = outcome.errors.message_list.join('<br/>')
              render text: errors, status: 422
            }
          end
        end
      end

      def destroy
        product_page = load_product_page
        @variant_id = params["id"]
        variant = Spree::Variant.find(@variant_id)
        product_page.displayed_variants.destroy(variant)
        respond_to do |format|
          format.js
        end
      end

      private

      def load_product_page
        Spree::ProductPage.find_by(permalink: params[:product_page_id])
      end
    end
  end
end
