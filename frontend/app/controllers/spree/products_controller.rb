module Spree
  class ProductsController < Spree::StoreController
    before_filter :load_product, :only => :show
    before_filter :load_selected_variant, :only => :show

# Commented out until we get a response from pinterest about 
# how they will deal with redirects
    before_filter :redirect_to_product_pages, :only => :show
    
    before_filter :check_stock, :only => :show
    rescue_from ActiveRecord::RecordNotFound, :with => :product_not_found
    helper 'spree/taxons'
    helper 'spree/products_ecom'
    
    respond_to :html

    # The index page for the old site should no longer be accessable
    def index
      redirect_to root_url
      #@searcher = Config.searcher_class.new(params)
      #@searcher.current_user = try_spree_current_user
      #@searcher.current_currency = current_currency
      #@products = @searcher.retrieve_products
    end

    def show
      return unless @product

      @variants = @product.variants_including_master.active(current_currency).includes([:option_values, :images])
      @product_properties = @product.product_properties.includes(:property)

      referer = request.env['HTTP_REFERER']
      if referer
        begin
          referer_path = URI.parse(request.env['HTTP_REFERER']).path
          # Fix for #2249
        rescue URI::InvalidURIError
          # Do nothing
        else
          if referer_path && referer_path.match(/\/t\/(.*)/)
            @taxon = Spree::Taxon.find_by_permalink($1)
          end
        end
      end
    end

    private
    def redirect_to_product_pages
      if Flip.product_pages?
        outcome = Spree::ProductPageRedirectionService.run(product: @product, variant: @selected_variant)
        redirect_to outcome.result[:url], status: outcome.result[:http_code]
      end
    end

    def check_stock
      outcome = Spree::VariantStockControlService.run(selected_variant: @selected_variant)
      if outcome.result[:redirect_to]
        flash[:notice] = outcome.result[:message]
        redirect_to outcome.result[:redirect_to]
      end
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

    def product_not_found
      flash[:error] = "Product not found"
      redirect_to root_url
    end

    def accurate_title
      @product ? @product.name : super
    end

    def load_product
      @product = Product.active(current_currency).where(permalink: (params[:id] || params[:product_id])).first
      @product ||= Product.with_deleted.find_by!(product_type: "virtual_product", permalink: (params[:id] || params[:product_id]))
    end
  end
end
