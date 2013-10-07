module Spree
  class TaxonsController < Spree::StoreController
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/products'

    respond_to :html

    def show
      @taxon = Taxon.find_by_permalink!(params[:id])
      return unless @taxon

      @searcher = build_searcher(params.merge(:taxon => @taxon.id))
      @products = @searcher.retrieve_products
    end

    private

    def pagination_helper( params )
      per_page = params[:per_page].to_i
      per_page = per_page > 0 ? per_page : Spree::Config[:products_per_page]
      page = (params[:page].to_i <= 0) ? 1 : params[:page].to_i 
      curr_page = page || 1
      [curr_page, per_page]
    end

    def accurate_title
      if @taxon
        @taxon.seo_title
      else
        super
      end
    end

  end
end
