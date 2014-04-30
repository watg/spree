module Spree
  module Api
    class AssemblyDefinitionsController < Spree::Api::BaseController
      skip_before_filter :check_for_user_or_api_key
      skip_before_filter :authenticate_user

      before_filter :assembly_definition

      def out_of_stock_variants
        respond_with( assembly_definition )
      end
      def out_of_stock_option_values
        respond_with( assembly_definition )
      end

      private

      def assembly_definition
        @assembly_definition ||= Spree::AssemblyDefinition.find(params[:id])
      end

    end
  end
end
