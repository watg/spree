module Spree
  class SearchController < Spree::StoreController
    helper 'spree/products'

    rescue_from ActionController::UnknownFormat, with: :render_404
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404

    def show
      @context = context
      searcher = Search::Base.new(
        keywords: params[:keywords],
        page: params[:page].to_i,
        per_page: params[:per_page].to_i,
      )

      @page = SearchPage.new(
        context: context,
        searcher: searcher,
        page: params[:page].to_i,
        per_page: params[:per_page].to_i
      )

      render "spree/taxons/show"
    end


  private

    def accurate_title
      @page.meta_title
    end

  end
end
