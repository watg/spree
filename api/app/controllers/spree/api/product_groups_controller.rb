module Spree
  module Api
    class ProductGroupsController < Spree::Api::BaseController
      def index
        if params[:ids]
          @product_groups = Spree::ProductGroup.accessible_by(current_ability, :read).where(id: params[:ids].split(','))
        else
          @product_groups = Spree::ProductGroup.accessible_by(current_ability, :read).order(:name).ransack(params[:q]).result
         
        end

        @product_groups = @product_groups.page(params[:page]).per(params[:per_page])
        respond_with(@product_groups)
      end

    end
  end
end
