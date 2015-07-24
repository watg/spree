module Spree
  module Admin
    class PersonalisationsController < ResourceController
      belongs_to 'spree/product', :find_by => :slug

      def update_all
        @product = Spree::Product.find_by slug: params[:product_id]
        outcome = Spree::UpdateAllPersonalisationService.run( params: params[:personalisations])
        if outcome.success?
          flash[:success] = flash_message_for(@product, :successfully_updated)
        else
          error = outcome.errors.message_list.join(', ')
          flash[:error] = "Could not update object #{@product.name} -- #{error}"
        end
        respond_with(@product) do |format|
          format.html { redirect_to spree.admin_product_personalisations_path(@product) }
          format.js   { render :layout => false }
        end
      end

      def create
        @product = Spree::Product.find_by slug: params[:product_id]
        @personalisation = params[:personalisation][:type].constantize.new( product_id: @product.id )
        if @personalisation.save
          flash[:success] = flash_message_for(@product, :successfully_created)
        else
          flash[:error] = flash_message_for(@product, :object_not_created)
        end
        respond_to do |format|
          format.html { redirect_to spree.admin_product_personalisations_path(@product)}
          format.js   { render :layout => false }
        end
      end

      def destroy
        @personalisation = @product.personalisations.find(params[:id])
        if @personalisation.destroy
          flash[:success] = flash_message_for(@product, :successfully_removed)
        else
          flash[:error] = flash_message_for(@product, :object_not_rmeoved)
        end
        respond_to do |format|
          format.html { redirect_to spree.admin_product_personalisations_path(@product)}
          format.js   { render :layout => false }
        end
      end

    end
  end
end
