module Spree
  class ProductsController < Spree::StoreController
    before_filter :load_product, :only => :show

    # Commented out until we get a response from pinterest about 
    # how they will deal with redirects
    before_filter :redirect_to_suite_pages, :only => :show
    before_filter :load_selected_variant, :only => :show
    before_filter :load_taxon, :only => :index

    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/taxons'

    respond_to :html

    def index
      @searcher = build_searcher(params)
      @products = @searcher.retrieve_products
      @taxonomies = Spree::Taxonomy.includes(root: :children)
    end

    def show
      return unless @product

      @variants = @product.variants_including_master.active(current_currency).includes([:option_values, :images])
      @product_properties = @product.product_properties.includes(:property)
      @taxon = Spree::Taxon.find(params[:taxon_id]) if params[:taxon_id]
    end

    private
    def redirect_to_suite_pages
      outcome = Spree::ProductRedirectionService.run(product: @product, variant: @selected_variant)
      redirect_to outcome.result[:url], status: outcome.result[:http_code]
    end

    def load_selected_variant
      if params[:option_values].blank?
        @selected_variant = @product.first_variant_or_master
      else
        selected_option_values = params[:option_values].split('/') rescue []
        @selected_variant = Spree::Variant.options_by_product(@product, selected_option_values)
        @selected_variant ||= @product.first_variant_or_master
      end

      if !params[:option_values].blank? && (@selected_variant.blank? || @selected_variant.is_master)
        flash[:error] = Spree.t(:unknown_selected_variant) + "  " + selected_option_values.join(', ')
        redirect_to product_url(@product)
      end
    end

    private
      def accurate_title
        if @product
          @product.meta_title.blank? ? @product.name : @product.meta_title
        else
          super
        end
      end

      def load_product
        if try_spree_current_user.try(:has_spree_role?, "admin")
          @products = Product.with_deleted
        else
          @products = Product.active(current_currency)
        end
        @product = @products.friendly.find(params[:id])
      end

      def load_taxon
        @taxon = Spree::Taxon.find(params[:taxon]) if params[:taxon].present?
      end
  end
end
