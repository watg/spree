module Spree
  class ProductPagesController < Spree::StoreController
    require_feature :product_pages

    PER_PAGE = 6
    
    respond_to :html

    def show
      respond_to do |format|
        format.html { show_html }
        format.js { show_js }
      end
    end

    def show_html
      outcome = Spree::ShowProductPageService.run(permalink: params[:id], tab: params[:tab], variant_id: params[:variant_id], currency: current_currency)
      if outcome.success?
        if url = outcome.result[:redirect_to]
          redirect_to url
        else
          @product_page = outcome.result[:decorated_product_page]
          @selected_variant = @product_page.selected_variant

          @variants = render_variants(PER_PAGE ,@selected_variant)
        end
      else
        Rails.logger.error( outcome.errors.message_list.join(', ') )
        redirect_to spree.root_path
      end
    end

    # This is used for the endless scrolling pagination we have put in place
    # Todo put this into a service
    def show_js

      if params[:variant_id]
        @selected_variant = Spree::Variant.find params[:variant_id]
      end

      @product_page = Spree::ProductPage.find_by_permalink(params[:id]).decorate( context:  {
        tab:     params[:tab],
        current_currency: current_currency,
        selected_variant: @selected_variant
      } )

      @variants = render_variants(PER_PAGE ,@selected_variant)
    end

    private

    def render_variants( per_page, selected_variant )
      @current_currency = current_currency
      @context = { target: @product_page.target, current_currency: @current_currency } 
      @product_page.made_by_the_gang_variants(selected_variant).page(params[:page]).per( per_page )
    end

  end
end
