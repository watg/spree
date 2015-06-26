module Spree
  module Api
    class ProductPartsController < Spree::Api::BaseController
      before_filter :product_part
      def variants
        respond_with( product_part )
      end
      private
      def product_part
        @product_part ||= Spree::ProductPart.find(params[:id])
      end
    end
  end
end
