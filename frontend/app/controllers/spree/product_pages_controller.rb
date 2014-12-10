module Spree
  class ProductPagesController < Spree::StoreController

    PER_PAGE = 6

    respond_to :html, :json
    rescue_from ActionController::UnknownFormat, with: :render_404

    before_filter :redirect_to_suites_pages, :only => :show

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

      selected_variants = if Spree::Variant.is_number(params[:variant_id])
        Spree::Variant.where(number: params[:variant_id], in_stock_cache: true)
      else
        Spree::Variant.where(id: params[:variant_id], in_stock_cache: true)
      end
      @selected_variant = selected_variants.first if selected_variants.any?

      tab_type = Spree::ProductPageTab.to_tab_type( params[:tab] )
      product_page = Spree::ProductPage.find_by_permalink(params[:id])
      selected_tab = product_page.tabs.where(tab_type: tab_type).first

      @product_page = product_page.decorate( context:  {
        tab:     selected_tab,
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

    def redirect_to_suites_pages
      if Flip.on?(:suites_feature)
        permalink = params.delete(:id)
        outcome = Spree::SuitePageRedirectionService.run(permalink: permalink, params: params)
        if outcome.valid?
          result = outcome.result
          redirect_to result[:url], status: result[:http_code]
        else
          redirect_to spree.root_path
        end
      end
    end

  end
end
