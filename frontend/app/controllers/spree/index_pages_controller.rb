module Spree
  class IndexPagesController < Spree::StoreController
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    
    PER_PAGE = 3

    def show
      index_page = Spree::IndexPage.find_by!(permalink: params[:id])
      @current_currency = current_currency
      @index_page = index_page.decorate(context: { current_currency: @current_currency })
            
      @items = @index_page.index_page_items.page(params[:page]).per( PER_PAGE )
    end
  end
end
