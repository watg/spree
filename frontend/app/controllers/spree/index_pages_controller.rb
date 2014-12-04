module Spree
  class IndexPagesController < Spree::StoreController
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404

    before_filter :redirect_to_taxon_pages, :only => :show

    PER_PAGE = 3
    TAXON_ALIASES = {
      'whats-new-kids' => 'whats-new/kids',
      'whats-new-women' => 'whats-new/women',
      'whats-new-men' => 'whats-new/men',
      'whats-new-seen-in-press' => 'whats-new/seen-in-press',
    }

    def show
      index_page = Spree::IndexPage.find_by!(permalink: params[:id])
      @current_currency = current_currency
      @index_page = index_page.decorate(context: { current_currency: @current_currency })

      @items = @index_page.index_page_items.page(params[:page]).per( PER_PAGE )
    end

    def redirect_to_taxon_pages
      return unless Flip.on?(:suites_feature)

      permalink = Spree::IndexPagesController::TAXON_ALIASES[params[:id]] || params[:id]

      taxon = Spree::Taxon.where(permalink: permalink).first
      if taxon
        redirect_to spree.nested_taxons_path(taxon), status: :moved_permanently
      else
        redirect_to root_path, status: :temporary_redirect
      end
    end

  end
end
