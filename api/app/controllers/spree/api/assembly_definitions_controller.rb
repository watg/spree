module Spree
  module Api
    class AssemblyDefinitionsController < Spree::Api::BaseController
      before_filter :assembly_definition
      def out_of_stock_variants
        respond_with( assembly_definition)
      end
      private
      def assembly_definition
        @assembly_definition ||= Spree::AssemblyDefinition.find(params[:id])
      end
    end
  end
end
