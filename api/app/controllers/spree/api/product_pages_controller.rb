module Spree
  module Api
    class ProductPagesController < Spree::Api::BaseController
      def index
        if params[:id]
          @product_pages = Spree::ProductPage.accessible_by(current_ability, :read).where(id: params[:id])
        else
          @product_pages = Spree::ProductPage.accessible_by(current_ability, :read).order(:name).ransack(params[:q]).result
        end

        @product_pages = @product_pages.page(params[:page]).per(params[:per_page])
        respond_with(@product_pages)
      end

    end
  end
end
