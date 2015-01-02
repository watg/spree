module Spree
  module Admin
    class ProductsController < ResourceController
      helper 'spree/products'

      before_filter :load_data, :except => :index
      create.before :create_before
      update.before :update_before
      helper_method :clone_object_url

      def show
        session[:return_to] ||= request.referer
        redirect_to( :action => :edit )
      end

      def index
        session[:return_to] = request.url
        respond_with(@collection)
      end

      def update
        outcome = Spree::UpdateProductService.run(
          product:          @object,
          details:          permit_attributes,
          prices:           params[:prices],
          stock_thresholds: params[:stock_thresholds]
        )
        if outcome.success?
          update_success(@object)
        else
          update_failed(@object, outcome.errors.message_list.join(', '))
        end
      end

      def destroy
        if @product.variants_including_master.detect { |v| v.part? == true }
          respond_to do |format|
            format.js  { render text: "Product is part of assembly.", status: :bad_request }
          end
        else
          @product.destroy
          flash[:success] = Spree.t('notice_messages.product_deleted')

          respond_with(@product) do |format|
            format.html { redirect_to collection_url }
            format.js  { render_js_for_destroy }
          end
        end
      end

      def clone
        @new = @product.duplicate

        if @new.save
          flash[:success] = Spree.t('notice_messages.product_cloned')
        else
          flash[:error] = Spree.t('notice_messages.product_not_cloned')
        end

        redirect_to edit_admin_product_url(@new)
      end

      def stock
        @variants = @product.variants
        @variants = [@product.master] if @variants.empty?
        @stock_locations = StockLocation.accessible_by(current_ability, :read)
        if @stock_locations.empty?
          flash[:error] = Spree.t(:stock_management_requires_a_stock_location)
          redirect_to admin_stock_locations_path
        end
      end

      def create_assembly_definition
        if @product.product_type.kit?
          @product.master.build_assembly_definition.save!
          @product.variants.select { |v| v.assembly_definition.blank? }.map(&:delete)
          flash[:success] = "Assembly definition successfully added!"
        else
          flash[:error] = "Cannot create an assembly definition for a non-kit product."
        end
        redirect_to edit_admin_product_url(@product)
      end

      protected

        def find_resource
          Product.with_deleted.friendly.find(params[:id])
        end

        def location_after_save
          spree.edit_admin_product_url(@product)
        end

        def load_data
          @taxons = Taxon.order(:name)
          @option_types = OptionType.order(:name)
          @tax_categories = TaxCategory.order(:name)
          @shipping_categories = ShippingCategory.order(:name)
          @product_groups = ProductGroup.order(:name)
          @suppliers = Supplier.order(:firstname, :lastname)
        end

        def collection
          return @collection if @collection.present?
          params[:q] ||= {}
          params[:q][:deleted_at_null] ||= "1"

          params[:q][:s] ||= "name asc"
          @collection = super
          @collection = @collection.with_deleted if params[:q][:deleted_at_null] == '0'
          # @search needs to be defined as this is passed to search_form_for
          @search = @collection.ransack(params[:q])
          @collection = @search.result.
                distinct_by_product_ids(params[:q][:s]).
                includes(product_includes).
                page(params[:page]).
                per(Spree::Config[:admin_products_per_page])

          @collection
        end

        def create_before
          return if params[:product][:prototype_id].blank?
          @prototype = Spree::Prototype.find(params[:product][:prototype_id])
        end

        def update_before
          # note: we only reset the product properties if we're receiving a post from the form on that tab
          return unless params[:clear_product_properties]
          params[:product] ||= {}
        end

        def product_includes
          [{ :variants => [:images, { :option_values => :option_type }], :master => [:images, :default_price]}]
        end

        def clone_object_url resource
          clone_admin_product_url resource
        end

        def permit_attributes
          params.require(:product).permit!
        end


      private

      def update_success(product)
        flash[:success] = flash_message_for(product, :successfully_updated)

        respond_with(product) do |format|
          format.html { redirect_to location_after_save }
          format.js   { render :layout => false }
        end
      end

      def update_failed(product, error)
        flash[:error] = "Could not update product #{product.name} -- #{error}"
        respond_with(product) do |format|
          format.html { redirect_to edit_admin_product_url(product) }
          format.js   { render :layout => false }
        end
      end

    end
  end
end
