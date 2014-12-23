module Spree
  class TaxonsController < Spree::StoreController
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/products'

    respond_to :html

    PER_PAGE = 27
    SHOW_ALL = 999

    def show
      @taxon = TaxonShowService.run!(permalink: params[:id])
      raise ActiveRecord::RecordNotFound if @taxon.nil?

      @suites = fetch_suites(@taxon)

      @taxonomies = Spree::Taxonomy.includes(root: :children)
      @currency = current_currency
      @context = { currency: @currency, device: device }
    end

    private

    def fetch_suites(taxon)
      selector = Spree::Suite.joins(:classifications, :tabs).includes(:image, :tabs, :target)
        .merge(Spree::Classification.where(taxon_id: taxon.id))
        .references(:classifications)

      # Ensure that if for some reason the page you are looking at is 
      # now empty then re-run the query with the first page
      suites = selector.page(curr_page).per(per_page)
      if suites.empty? and curr_page > 1
        params[:page] = 1
        suites = selector.page(curr_page).per(per_page)
      end
      suites
    end

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
