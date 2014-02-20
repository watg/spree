module Spree
  module Admin
    class PricesController < ResourceController
      belongs_to 'spree/product', :find_by => :permalink

      def create
        outcome = Spree::VariantPricesService.run(filtered_params)
        if !outcome.success?
          flash.now[:error] = outcome.errors.message_list.join(', ')
        end
        render :index
      end

      private
      def filtered_params
        {
          product:              @product,
          vp:                   params[:vp],
          in_sale:              params[:in_sale] || [],
          commit:               params[:commit],
        }
      end

    end
  end
end
