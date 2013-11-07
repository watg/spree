module Spree
  module Admin
    class PersonalisationsController < ResourceController
      belongs_to 'spree/product', :find_by => :permalink


      # TODO:
      # 1. Services for create
      # 2. dynamic new
      # 3. tests
      # 4. form for monogram
      # 5. image upload

      # We can only create a monogram for now, so let's just hardcode
      # it 
      def new
        @personalisation = Spree::Personalisation::Monogram.new
      end

      def create
        @personalisation = params[:personalisation][:type].constantize.new
        @personalisation.product_id = @product.id
        @personalisation.save
      end

      def destroy
        @personalisation = @product.personalisations.find(params[:id])
        if @personalisation.destroy
          flash[:success] = Spree.t(:successfully_removed, :resource => Spree.t(:personalisations))
        end
        respond_to do |format|
          format.html { redirect_to spree.admin_product_personalisations_path(@product)}
          format.js   { render :layout => false }
        end
      end

      def xcreate
        invoke_callbacks(:create, :before)
        outcome = Spree::CreatePersonalisationService.run(product: @product, params: params[:personalisation])
        if outcome.success?
          create_success(@object)
        else
          create_failed(@object, outcome.errors.message_list.join(', '))
        end
      end

      def xupdate
        outcome = Spree::UpdatePersonalisationService.run(personalisation: @personalisations, details: params[:personalisations])
        if outcome.success?
          update_success(@personalisation)
        else
          update_failed(@personalisation, outcome.errors.message_list.join(', '))
        end
      end

      private

      def create_success(object)
        flash[:success] = flash_message_for(object, :successfully_created)
        respond_with(object) do |format|
          format.html { redirect_to location_after_save }
          format.js   { render :layout => false }
        end
      end

      def create_failed(object, error)
        flash[:error] = "Could not create object #{object.name} -- #{error}"
        respond_with(object) do |format|
          format.html { redirect_to new_admin_product_variant_url(@object.product.permalink) }
          format.js   { render :layout => false }
        end
      end

      def update_success(object)
        flash[:success] = flash_message_for(object, :successfully_updated)
        respond_with(object) do |format|
          format.html { redirect_to location_after_save }
          format.js   { render :layout => false }
        end
      end

      def update_failed(object, error)
        flash[:error] = "Could not update object #{object.name} -- #{error}"
        respond_with(object) do |format|
          format.html { redirect_to edit_admin_product_variant_url(object.product.permalink, object.id) }
          format.js   { render :layout => false }
        end
      end
    end
  end
end
