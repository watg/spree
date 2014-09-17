module Spree
  module Admin
    class SuppliersController < ResourceController

      before_filter :set_defaults, :only => [:new]

      protected

      def set_defaults
        @object.mid_code = Spree::Supplier.default_mid_code
        @object.country = Spree::Supplier.default_country
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
        edit_admin_supplier_path(@supplier)
      end

    end
  end
end
