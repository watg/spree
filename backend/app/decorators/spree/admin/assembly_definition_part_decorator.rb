module Spree
  module Admin
    class AssemblyDefinitionPartDecorator < Draper::Decorator
      decorates '::Spree::AssemblyDefinition'
      delegate_all

      def url
        #api_assembly_definition_part_variants_path(id: self.id)
        "/api/assembly_definition_parts/#{self.id}/variants"
      end
    end
  end
end
