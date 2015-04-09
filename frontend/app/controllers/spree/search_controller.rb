module Spree
  # controller for the search page
  class SearchController < Spree::StoreController
    helper "spree/products"

    rescue_from ActionController::UnknownFormat, with: :render_404
    rescue_from ActiveRecord::RecordNotFound, with: :render_404

    def show
      @page = SearchPageFacade.new(
      context: context,
      searcher: build_searcher
      )
      render "spree/taxons/show"
    end

    private

    def build_searcher
      Search::Base.new(
      keywords: params[:keywords],
      page: params[:page].to_i,
      per_page: params[:per_page].to_i
      )
    end

    def accurate_title
      @page.meta_title
    end
  end
end
