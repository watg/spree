module Spree
  module Admin
    class ProductPagesController < ResourceController

      def update
        outcome = Spree::UpdateProductPageService.run(product_group: @object, details: params[:product_group], tabs: params[:tabs])
        if outcome.success?
          update_success(@object)
        else
          update_failed(@object, outcome.errors.message_list.join(", "))
        end
      end

      protected
      def find_resource
        ProductPage.find_by_id(params[:id])
      end

      def update_success(product_group)
        flash[:success] = flash_message_for(product_group, :successfully_updated)

        respond_with(product_group) do |format|
          format.html { redirect_to spree.edit_admin_product_group_url(product_group) }
          format.js   { render :layout => false }
        end
      end

      def update_failed(product_group, error)
        flash[:error] = "Could not update product group #{product_group.name} -- #{error}"
        respond_with(product_group) do |format|
          format.html { redirect_to edit_admin_product_group_url(product_group) }
          format.js   { render :layout => false }
        end
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
