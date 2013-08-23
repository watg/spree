module Spree
  module Admin
    class PricesController < ResourceController
      belongs_to 'spree/product', :find_by => :permalink

      def create
        service = Spree::VariantPricesService.new(self)
        service.perform(filtered_params)
        render :index
      end

      private
      def filtered_params
        {
          vp:                  params[:vp],
          variant_in_sale_ids: params[:variant_in_sale_ids]
        }
      end

      def create_callback(errors)
        flash[:error] = errors.join(', ') unless errors.blank?
      end
    end
  end
end
