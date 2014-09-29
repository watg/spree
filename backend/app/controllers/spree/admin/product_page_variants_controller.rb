module Spree
  module Admin
    class ProductPageVariantsController < BaseController
      before_filter :load_product_page
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
        @variant_id = params["variant_id"]
        outcome = Spree::CreateProductPageVariantsService.run(
          product_page: @product_page,
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

      # This is not very DRY but I have written it to be easy to follow and modify
      # this needs to be thrown away once we turn off the product page variants
      def move_stock
        sl = Spree::StockLocation.first
        source_variant = Spree::Variant.where(id: params[:id]).first
        product = Spree::Product.where(id: params[:target_product_id]).first
        product_page = Spree::ProductPage.where(permalink: params[:product_page_id]).first

        # Don't continue if you can not find the source variant, this should never
        # happen
        unless source_variant
          flash[:error] = "Source Variant could not be found"
          redirect_to admin_product_page_variants_path(@product_page)
          return
        end

        unless product
          flash[:error] = "Please provide a product"
          redirect_to admin_product_page_variants_path(@product_page)
          return
        end

        # Check if the target variant already exists, we do this by comparing
        # the option values of each variant, we could have used variant.options_text
        # instead to compare
        target_variant = product.variants.detect do |v|
          v.option_values.sort == source_variant.option_values.sort
        end

        if target_variant
          # We have a target, this means the stock already exists

          if params[:force_move] == 'true'
            # If we check the force checkbox then unstock the source target
            # and stock the target
            sl.transaction do
              source_variant.stock_items.each do |si|
                sl.unstock(source_variant,si.count_on_hand,target_variant,si.supplier)
                sl.restock(target_variant,si.count_on_hand,source_variant,si.supplier)
              end
            end

            # Delete the variant from the product page as we no longer need them
            ppvs = Spree::ProductPageVariant.where(variant_id: source_variant.id, product_page_id: product_page.id )
            ppvs.delete_all

            flash[:success] = "The stock was successfully moved! "

            source_variant_product = source_variant.product

            # Delete the variant itself
            source_variant.destroy

            # Delete the product if only a master variant is present
            if source_variant.product.variants_including_master.count == 1
              source_variant_product.destroy
              flash[:success] += "Product was also deleted."
            else
              flash[:success] += " !! Product was not deleted !!"
            end

          else
            # If force is not true then warn the user that a target already exists
            flash[:error] = "The stock item: #{target_variant.options_text} already exists, please check 'force' before clicking MOVE, if you really want to move it"
          end

        else
          # If a target does not exist then we can safely just move the variant to it's new
          # product
          source_variant.product = product
          source_variant.save


          # Finally delete this from the product page variants as
          # we no longer need it
          ppvs = Spree::ProductPageVariant.where(variant_id: source_variant.id, product_page_id: product_page.id )
          ppvs.delete_all
          flash[:success] = "The stock was successfully moved!"
        end


        redirect_to admin_product_page_variants_path(@product_page)
      end

    def destroy
        @variant_id = params["id"]
        variant = Spree::Variant.find(@variant_id)
        @product_page.displayed_variants.destroy(variant)
        respond_to do |format|
          format.js
        end
      end

      private

      def load_product_page
        @product_page = Spree::ProductPage.find_by(permalink: params[:product_page_id])
      end
    end
  end
end
