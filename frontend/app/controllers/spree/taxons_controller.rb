module Spree
  # controller for taxons page
  class TaxonsController < Spree::StoreController
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    helper "spree/products"

    respond_to :html

    def show
      @page = IndexPageFacade.new(
        taxon: fetch_taxon,
        context: context,
        page: params[:page].to_i,
        per_page: params[:per_page].to_i
      )
    end

    private

    def fetch_taxon
      taxon ||= Spree::TaxonShowService.run!(permalink: params[:id])
      raise ActiveRecord::RecordNotFound if taxon.nil?
      taxon
    end

    def accurate_title
      @page.meta_title
    end
  end
end
