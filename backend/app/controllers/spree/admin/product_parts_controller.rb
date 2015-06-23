module Spree
  module Admin
    class ProductPartsController < ResourceController
      belongs_to 'spree/product', :find_by => :slug
      before_filter :permit_attributes, only: [:update_all]

      def index
      end

      # TODO: Remove all of the assembly_definition controllers
      # TODO: move specs
      # TODO: Delete assem def
      # TODO: Rename models
      # TODO: Rename assembly_defintiion_variant
      
      # TODO: move into a presenter
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

      def model_class
        # TODO: remove once we we rename AssemDefPart
        AssemblyDefinitionPart
      end

        # TODO: remove once we we rename AssemDefPart
      def collection_url(opts = {})
        spree.admin_product_product_parts_url(params[:product_id], opts)
      end

      def permit_attributes
        params.require(:product).permit!
      end

    end
  end
end

