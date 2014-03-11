module Spree
  module Admin
    class AssemblyDefinitionDecorator < Draper::Decorator
      decorates 'Spree::AssemblyDefinition'
      delegate_all

      def url
        # api_assembly_definition_parts_path(id: self.id)
        "/shop/api/assembly_definitions/#{self.id}/parts"
      end
    end
  end
end
