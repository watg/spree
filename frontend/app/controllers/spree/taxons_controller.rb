module Spree
  class TaxonsController < Spree::StoreController
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/products'

    respond_to :html

    PER_PAGE = 27

    def show
      @taxon = Taxon.find_by_permalink!(params[:id])
      return unless @taxon

      # TODO: Try to get the search working
      # @searcher = build_searcher(params.merge(taxon: @taxon.id, include_images: true))
      # @products = @searcher.retrieve_products

      taxons_ids = @taxon.self_and_descendants.pluck(:id)

      @suites = Spree::Suite.joins(classifications: :taxon).joins(:tabs)
        .includes(:image, :tabs, :target)
        .merge(Spree::Taxon.where(id: taxons_ids).order(:lft))
        .references(:taxon)
        .page(curr_page).per(per_page)

      @taxonomies = Spree::Taxonomy.includes(root: :children)
      @currency = current_currency
      @context = { currency: @currency, device: device }
    end

  private
  
    def per_page
      per_page = params[:per_page].to_i
      (per_page <= 0) ? PER_PAGE : per_page
    end

    def curr_page
      curr_page = params[:page].to_i
      (curr_page <= 0) ? 1 : curr_page
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
