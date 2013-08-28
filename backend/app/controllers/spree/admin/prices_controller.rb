module Spree
  module Admin
    class PricesController < ResourceController
      belongs_to 'spree/product', :find_by => :permalink

      def create
        outcome = Spree::VariantPricesService.run(filtered_params)
        if !outcome.success?
          flash[:error] = outcome.errors.message_list.join(', ')
        end
        render :index
      end

      private
      def filtered_params
        {
          product:              @product,
          vp:                   params[:vp],
          variant_in_sale_ids:  params[:variant_in_sale_ids],
          supported_currencies: supported_currencies
        }
      end

    end
  end
end
