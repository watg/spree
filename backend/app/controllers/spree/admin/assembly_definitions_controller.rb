module Spree
  module Admin
    class AssemblyDefinitionsController < ResourceController

      def show
        @assembly_definition = Spree::AssemblyDefinition.find(params[:id])
        @product = @assembly_definition.variant.product
      end

      def available_supply_products
        @assembly_definition = Spree::AssemblyDefinition.find(params[:id])
        if params[:q].blank?
          @available_products = []
        else
          query = "%#{params[:q]}%"
          @available_products = Spree::Product.
            not_deleted.
            available.
            joins(:master).
            where("(spree_products.name ILIKE ? OR spree_variants.sku ILIKE ?) AND can_be_part = ? AND product_type NOT IN (?)", query, query, true, ['kit', 'virtual_product']).
            limit(30)

          @available_products.uniq!
        end
        render 'spree/admin/assembly_definitions/available'
      end


      def location_after_save
        admin_assembly_definition_path(@assembly_definition)
      end

    end
  end
end

