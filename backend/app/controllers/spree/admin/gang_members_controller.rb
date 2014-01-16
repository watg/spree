module Spree
  module Admin
    class GangMembersController < ResourceController

      protected

      def find_resource
        GangMember.find_by_permalink(params[:id])
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

    end
  end
end
