module Spree
  module Api
    class VariantsController < Spree::Api::BaseController

      before_filter :product
      before_filter :product_page, :only => [:index]

      def create
        authorize! :create, Variant
        @variant = scope.new(variant_params)
        if @variant.save
          respond_with(@variant, status: 201, default_template: :show)
        else
          invalid_resource!(@variant)
        end
      end

      def destroy
        @variant = scope.accessible_by(current_ability, :destroy).find(params[:id])
        @variant.destroy
        respond_with(@variant, status: 204)
      end

      def index
        if params[:id]
          @variants = Spree::Variant.accessible_by(current_ability, :read).where(id: params[:id])
        else
          @variants = scope.includes(:option_values).ransack(params[:q]).result
        end

        @variants = @variants.page(params[:page]).per(params[:per_page])

        respond_with(@variants)
      end

      def new
      end

      def show
        @variant = scope.includes(:option_values).find(params[:id])
        respond_with(@variant)
      end

      def update
        @variant = scope.accessible_by(current_ability, :update).find(params[:id])
        if @variant.update_attributes(variant_params)
          respond_with(@variant, status: 200, default_template: :show)
        else
          invalid_resource!(@product)
        end
      end

      private

        def product
          @product ||= Spree::Product.accessible_by(current_ability, :read).find_by(permalink: params[:product_id]) if params[:product_id]
        end

        def product_page
          if params[:product_page_id]
            @product_page ||= Spree::ProductPage.accessible_by(current_ability, :read).find(params[:product_page_id])
          end
        end

        def scope
          if @product
            unless current_api_user.has_spree_role?('admin') || params[:show_deleted]
              variants = @product.variants_including_master.accessible_by(current_ability, :read)
            else
              variants = @product.variants_including_master.with_deleted.accessible_by(current_ability, :read)
            end
          elsif @product_page
            variants = @product_page.displayed_variants.accessible_by(current_ability, :read)
          else
            variants = Variant.accessible_by(current_ability, :read)
            if current_api_user.has_spree_role?('admin')
              unless params[:show_deleted]
                variants = Variant.accessible_by(current_ability, :read).active
              end
            else
              variants = variants.active
            end
          end
          variants
        end

        def variant_params
          params.require(:variant).permit(permitted_variant_attributes)
        end
    end
  end
end
