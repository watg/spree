module Spree
  module Admin
    class ProductGroupsController < ResourceController

      protected
      def find_resource
        ProductGroup.find_by_id(params[:id])
      end

      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        params[:q][:s] ||= "name asc"
        @collection = super
        # @search needs to be defined as this is passed to search_form_for
        @search = @collection.ransack(params[:q])
        @collection = @search.result.
          page(params[:page]).
          per( 15 )
        @collection
      end

      def location_after_save
        edit_admin_product_group_path(@product_group)
      end
    end
  end
end
