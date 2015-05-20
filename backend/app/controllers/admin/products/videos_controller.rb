module Admin 
  module Products
    class VideosController < ApplicationController
      include Spree::Core::ControllerHelpers::Auth
      include Spree::Core::ControllerHelpers::Common
      include Spree::Core::ControllerHelpers::Store
      include Spree::Core::ControllerHelpers::Order

      layout '/admin/layouts/admin'

      def index
        @product = Spree::Product
                        .find_by_slug(params[:product_id]) 
        @videos  = Video.all
                         .map{ |v| VideoPresenter.new(v, @product) }
      end

      def create
        @product = CreateProductVideosService.run(params[:product])
        @product.valid? && flash[:success] = "Product updated"
        redirect_to "/admin/products/#{@product.result.slug}/edit"
      end
    end
  end
end