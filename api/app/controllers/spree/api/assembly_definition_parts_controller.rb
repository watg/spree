module Spree
  module Api
    class AssemblyDefinitionPartsController < Spree::Api::BaseController
      before_filter :assembly_definition_part
      def variants
        respond_with( assembly_definition_part )
      end
      private
      def assembly_definition_part
        @assembly_definition_part ||= Spree::AssemblyDefinitionPart.find(params[:id])
      end
    end
  end
end
