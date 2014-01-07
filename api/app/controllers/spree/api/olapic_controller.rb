module Spree
  module Api
    class OlapicController < Spree::Api::BaseController
      include Rails.application.routes.url_helpers
      def index
        # Hack to filter out all the product_pages we actually use ( they will have a permalink )
        @product_pages = Spree::ProductPage.accessible_by(current_ability, :read).where.not(permalink: nil)
        @product_pages = @product_pages.page(params[:page]).per(params[:per_page])
        respond_with(@product_pages)
      end

    end

  end
end
