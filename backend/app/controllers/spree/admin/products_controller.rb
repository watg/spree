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
        outcome = Spree::UpdateProductService.run(product: @object, details: permit_attributes, prices: params[:prices])
        if outcome.success?
          update_success(@object)
        else
          update_failed(@object, outcome.errors.message_list.join(', '))
        end
      end

      def destroy
        @product = Product.find_by_permalink!(params[:id])
        @product.destroy

        flash[:success] = Spree.t('notice_messages.product_deleted')

        respond_with(@product) do |format|
          format.html { redirect_to collection_url }
          format.js  { render_js_for_destroy }
        end
      end

      def clone
        @new = @product.duplicate

        if @new.save
          flash[:success] = Spree.t('notice_messages.product_cloned')
        else
          flash[:success] = Spree.t('notice_messages.product_not_cloned')
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

      protected

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

      def find_resource
        Product.find_by_permalink!(params[:id])
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
        @gang_members = GangMember.order(:firstname, :lastname)
      end

      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        params[:q][:deleted_at_null] ||= "1"

        params[:q][:s] ||= "name asc"
        @collection = super
        @collection = @collection.with_deleted if params[:q].delete(:deleted_at_null).blank?
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
        type = Spree::MartinProductType.find(params[:product][:martin_type_id])
        params[:product][:product_type] = mapping[type.name]

        return if params[:product][:prototype_id].blank?
        @prototype = Spree::Prototype.find(params[:product][:prototype_id])
      end

      def product_includes
        [{ :variants => [:images, { :option_values => :option_type }], :master => [:images, :default_price]}]
      end

      def mapping
        {
          'peruvian'  => 'product',
          'gang'      => 'made_by_the_gang',
          'kit'       => 'kit',
          'yarn'      => 'accessory',
          'needle'    => 'accessory',
          'pattern'   => 'pattern',
          'e_gift_card' => 'gift_card',
          'clasp'     => 'accessory',
          'parcel'    => 'parcel'
        }
      end

      def clone_object_url resource
        clone_admin_product_url resource
      end

      def permit_attributes
        params.require(:product).permit!
      end

    end
  end
end
