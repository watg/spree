module Spree
  class ProductRedirectionService < Mutations::Command
    optional do
      duck :product
      duck :variant
    end

    def execute
      {
        url:       suite_url,
        http_code: code,
        flash:     message
      }
    end
    
    private
    def code
      ((product.blank? || suite.blank?) ? 302 : 301)
    end

    def message
      return "Item not found" if product.blank?
      return "Page not found" if suite.blank?
    end

    def suite_url
      return '/' if product.blank?
      return '/' if suite.blank?

      base = [ 'product', suite, suite.tabs.first.tab_type]
      base << variant.number if variant
      
      '/' + base.compact.join('/')
    end
    
    def suite
      return @page.permalink if @page
      @page = Spree::Suite.joins(tabs: [:product]).merge(Spree::Product.where(slug: product.slug)).first
      @page.permalink if @page
    end
    
    
  end
end
