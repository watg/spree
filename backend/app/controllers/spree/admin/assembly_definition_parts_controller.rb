module Spree
  module Admin
    class AssemblyDefinitionPartsController < ResourceController
      before_filter :load_data

      def create
        @assembly_definition.parts.create(create_attrs) if create_attrs[:count] > 0
        render 'spree/admin/assembly_definitions/update_parts_table', layout: false
      end

      private

      def load_data
        @assembly_definition = Spree::AssemblyDefinition.find(params[:assembly_definition_id])
      end

      def create_attrs
        update_attrs.merge(required_attrs)
      end

      def update_attrs
        {
          optional:     params[:part_optional] == 'true' ,
          count:        params[:part_count].to_i,
          presentation: params[:part_presentation],
          variants:     Spree::Variant.where(id: params[:part_variants] )
        }
      end

      def required_attrs
        {
          part_id: params[:part_product_id].to_i,
          product_id: @assembly_definition.variant.product.id
        }
      end
    end
  end
end

