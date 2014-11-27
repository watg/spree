module Spree
  module Admin
    class VariantsController < ResourceController
      belongs_to 'spree/product', :find_by => :slug
      new_action.before :new_before
      before_filter :load_data, :only => [:new, :create, :edit, :update]

      def create
        invoke_callbacks(:create, :before)
        @variant = Spree::Variant.new( product_id: @product.id )
        outcome = Spree::UpdateVariantService.run(
          variant: @variant,
          details: params[:variant],
          prices:  params[:prices]
        )
        if outcome.valid?
          create_success(@object)
        else
          create_failed(@object, outcome.errors.full_messages.to_sentence)
        end
      end

      def update
        outcome = Spree::UpdateVariantService.run(
          variant:          @variant,
          details:          params[:variant],
          prices:           params[:prices],
          stock_thresholds: params[:stock_thresholds],
        )
        if outcome.valid?
          update_success(@variant)
        else
          update_failed(@variant, outcome.errors.full_messages.to_sentence)
        end
      end

      def destroy
        if @variant.part? == true
          respond_to do |format|
            format.js  { render text: "Variant is part of assembly.", status: :bad_request }
          end
        else
          if @variant.destroy
            flash[:success] = Spree.t('notice_messages.variant_deleted')
          else
            flash[:success] = Spree.t('notice_messages.variant_not_deleted')
          end

          respond_with(@variant) do |format|
            format.html { redirect_to admin_product_variants_url(params[:product_id]) }
            format.js  { render_js_for_destroy }
          end
        end
      end

      def create_sku
        @variant.create_sku
        @variant.save
        redirect_to edit_admin_product_variant_url(@variant.product.slug, @variant.id)
      end

      protected

      def new_before
        @variant.attributes = @product.master.attributes.except('id', 'created_at', 'deleted_at', 'updated_at', 'is_master')
        @variant.prices = @product.master.prices.dup
        @variant.stock_thresholds = @product.master.stock_thresholds.dup
      end

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
          format.html { redirect_to new_admin_product_variant_url(@object.product.slug) }
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
          format.html { redirect_to edit_admin_product_variant_url(object.product.slug, object.id) }
          format.js   { render :layout => false }
        end
      end

      def collection
        @deleted = (params.key?(:deleted) && params[:deleted] == "on") ? "checked" : ""

        if @deleted.blank?
          @collection ||= super
        else
          @collection ||= Variant.where(:product_id => parent.id).deleted
        end
        @collection
      end

      private

      def load_data
        @tax_categories = TaxCategory.order(:name)
      end

    end
  end
end
