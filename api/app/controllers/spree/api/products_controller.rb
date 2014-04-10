module Spree
  module Api
    class ProductsController < Spree::Api::BaseController

      def index
        if params[:ids]
          @products = product_scope.where(:id => params[:ids].split(","))
        else
          @products = product_scope.includes(variants: :images).ransack(params[:q]).result.uniq
        end

        @products = @products.distinct.page(params[:page]).per(params[:per_page])
        expires_in 15.minutes, :public => true
        headers['Surrogate-Control'] = "max-age=#{15.minutes}"
      end

      def show
        @product = find_product(params[:id])
        expires_in 15.minutes, :public => true
        headers['Surrogate-Control'] = "max-age=#{15.minutes}"
        headers['Surrogate-Key'] = "product_id=1"
      end

      # Takes besides the products attributes either an array of variants or
      # an array of option types.
      #
      # By submitting an array of variants the option types will be created
      # using the *name* key in options hash. e.g
      #
      #   product: {
      #     ...
      #     variants: {
      #       price: 19.99,
      #       sku: "hey_you",
      #       options: [
      #         { name: "size", value: "small" },
      #         { name: "color", value: "black" }
      #       ]
      #     }
      #   }
      #
      # Or just pass in the option types hash:
      #
      #   product: {
      #     ...
      #     option_types: ['size', 'color']
      #   }
      #
      # By passing the shipping category name you can fetch or create that
      # shipping category on the fly. e.g.
      #
      #   product: {
      #     ...
      #     shipping_category: "Free Shipping Items"
      #   }
      #
      def create
        authorize! :create, Product
        params[:product][:available_on] ||= Time.now
        set_up_shipping_category

        @product = Product.new(product_params)
        if @product.save
          variants_params.each do |variant_attribute|
            # make sure the product is assigned before the options=
            @product.variants.create({ product: @product }.merge(variant_attribute))
          end

          option_types_params.each do |name|
            option_type = OptionType.where(name: name).first_or_initialize do |option_type|
              option_type.presentation = name
              option_type.save!
            end

            @product.option_types << option_type unless @product.option_types.include?(option_type)
          end

          respond_with(@product, :status => 201, :default_template => :show)
        else
          invalid_resource!(@product)
        end
      end

      def update
        @product = find_product(params[:id])
        authorize! :update, @product

        if @product.update_attributes(product_params)
          variants_params.each do |variant_attribute|
            # update the variant if the id is present in the payload
            if variant_attribute['id'].present?
              @product.variants.find(variant_attribute['id'].to_i).update_attributes(variant_attribute)
            else
              # make sure the product is assigned before the options=
              @product.variants.create({ product: @product }.merge(variant_attribute))
            end
          end

          option_types_params.each do |name|
            option_type = OptionType.where(name: name).first_or_initialize do |option_type|
              option_type.presentation = name
              option_type.save!
            end

            @product.option_types << option_type unless @product.option_types.include?(option_type)
          end

          respond_with(@product.reload, :status => 200, :default_template => :show)
        else
          invalid_resource!(@product)
        end
      end

      def destroy
        @product = find_product(params[:id])
        authorize! :destroy, @product
        @product.destroy
        respond_with(@product, :status => 204)
      end

      private
        def product_params
          product_params = params.require(:product).permit(permitted_product_attributes)
          if product_params[:taxon_ids].present?
            product_params[:taxon_ids] = product_params[:taxon_ids].split(',')
          end
          product_params
        end

        def variants_params
          variants_key = if params[:product].has_key? :variants
            :variants
          else
            :variants_attributes
          end

          params.require(:product).permit(
            variants_key => [permitted_variant_attributes, :id],
          ).delete(variants_key) || []
        end

        def option_types_params
          params[:product].fetch(:option_types, [])
        end

        def set_up_shipping_category
          if shipping_category = params[:product].delete(:shipping_category)
            id = ShippingCategory.find_or_create_by(name: shipping_category).id
            params[:product][:shipping_category_id] = id
          end
        end
    end
  end
end
