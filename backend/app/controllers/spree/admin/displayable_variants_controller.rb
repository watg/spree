module Spree
  module Admin
    class DisplayableVariantsController < Spree::Admin::BaseController  

      def index
        @product_id = params[:product_id]
        @products = Spree::Product.saleable?.all
        @variants = Spree::Variant.displayable(@product_id).all if @product_id
      end

      def create
        service = Spree::DisplayableVariantsService.new(self)
        service.perform(params[:product_id], params[:variant_ids])
      end

      private
      def update_success(product)
        flash[:success] = "Success"
        redirect_to admin_displayable_variants_url(product_id: product.id)
      end

      def update_failure(product, error)
        flash[:error] = "Could not update variants for product #{product.name}"
        Rails.logger.error error.backtrace
        redirect_to admin_displayable_variants_url()
      end
      
    end
  end
end
