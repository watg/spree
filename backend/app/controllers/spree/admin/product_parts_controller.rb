module Spree
  module Admin
    class ProductPartsController < ResourceController
      belongs_to 'spree/product', :find_by => :slug
      before_action :set_product_tab_presenter
      before_filter :permit_attributes, only: [:update_all]

      def index
      end

      def available
        @product = Spree::Product.find_by_slug(params[:product_id])
        if params[:q].blank?
          @available_parts = []
        else
          query = "%#{params[:q]}%"
          @available_parts = Spree::Product.
            not_deleted.
            available.
            not_assembly.
            joins(:master).
            where("(spree_products.name ILIKE ? OR spree_variants.sku ILIKE ?)", query, query).
            limit(30)
          @available_parts.uniq!
        end
        render layout: false
      end

      private

      def permit_attributes
        params.require(:product).permit!
      end

    end
  end
end

