module Spree
  class ShowProductPageService < Mutations::Command

    include ActionView::Helpers
    include ActionDispatch::Routing
    include Rails.application.routes.url_helpers

    required do
      string :permalink
      string :tab, empty: true, :nils => true
      string :currency
    end

    optional do
      string :variant_id, empty: true, :nils => true
    end
          
    def execute
      product_page = Spree::ProductPage.where( permalink: permalink ).first
      result = {redirect_to: nil}
      if product_page

        if variant_id && tab.present?
          if Spree::Variant.is_number(variant_id)
            selected_variant = Spree::Variant.where(number: variant_id, in_stock_cache: true).first
          else
            selected_variant = Spree::Variant.where(id: variant_id, in_stock_cache: true).first
          end
        end

        decorated_product_page = decorate_product_page(product_page, selected_variant)
        if valid_tab(decorated_product_page, tab) 
          result[:decorated_product_page] = decorated_product_page
        else
          result[:redirect_to] = first_valid_tab(decorated_product_page)
        end
      else
        result[:redirect_to] = Spree::Core::Engine.routes.url_helpers.root_path
      end
      result
    end

    private

    def decorate_product_page(product_page, selected_variant)
       product_page.decorate(context: {
          tab:     tab,
          current_currency: currency,
          selected_variant: selected_variant
        } )
    end

    def valid_tab(product_page, tab)
      # a tab was not supplied and we were not expecting any
      if ( tab.blank? and product_page.tabs_as_permalinks.blank? )
        true
        # product_page contains the tab supplied
      elsif product_page.tabs_as_permalinks.include? tab
        true
      else
        false
      end
    end

    def first_valid_tab(product_page)
      if product_page.tabs_as_permalinks.any?
        Spree::Core::Engine.routes.url_helpers.product_page_path(product_page.permalink) + '/' + product_page.tabs_as_permalinks.first
      else
        Spree::Core::Engine.routes.url_helpers.product_page_path(product_page.permalink)
      end
    end

  end
end
