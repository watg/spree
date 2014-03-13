module Spree
  module Admin
    class AssemblyDefinitionPartsController < Spree::Admin::BaseController
      before_filter :find_item

      def update_position
        if not positions.blank?
          Spree::AssemblyDefinitionPart.update(positions.keys, positions.values)
        end
        render text: "ok"
      end

      def create
        @assembly_definition.parts.create(create_attrs) if create_attrs[:count] > 0
        render 'spree/admin/assembly_definitions/update_parts_table', layout: false
      end

      def update
        record = Spree::AssemblyDefinitionPart.find(params[:id])
        if update_attrs[:count] > 0
          record.update_attributes(update_attrs)
        else
          record.destroy
        end
        render 'spree/admin/assembly_definitions/update_parts_table'
      end

      private

      def find_item
        @assembly_definition = Spree::AssemblyDefinition.find_by_id(params[:assembly_definition_id])
      end

      def create_attrs 
        update_attrs.merge(product_id: params[:part_product_id].to_i)
      end

      def update_attrs
        {
          optional:     params[:part_optional] == 'true' ,
          count:        params[:part_count].to_i,
          presentation: params[:part_presentation],
          variants:     Spree::Variant.where(id: params[:part_variants] )
        }
      end

      def positions
        _p = params[:positions] || {}
        _p.inject({}) {|hsh, d| hsh[d[0]]= {position: d[1]}; hsh}
      end
    end
  end
end

