module Spree
  module Admin
    class DisplayableVariantsController < Spree::Admin::BaseController  

      def index
        @product_id = params[:product_id]
        @products = Spree::Product.saleable?.all
        @variants = Spree::Variant.displayable(@product_id).all if @product_id
      end

      def create
        outcome = Spree::DisplayableVariantsService.run(filtered_params)
        if outcome.success?
          update_success
        else
          update_failure(outcome.errors.message_list)
        end
      end

      private
      def filtered_params
        {
          product_id:  params[:product_id],
          variant_ids: (params[:variant_ids].blank? ? [] : params[:variant_ids])
        }
      end
      
      def update_success
        flash[:success] = "Success"
        redirect_to admin_displayable_variants_url(product_id: params[:product_id])
      end

      def update_failure(error_list)
        msg = error_list.join ", "
        flash[:error] = "Could not update variants for product #{msg}"
        Rails.logger.error msg
        redirect_to admin_displayable_variants_url()
      end
      
    end
  end
end
