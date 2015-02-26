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

      base = ['product', suite, tab(product)]

      base << variant.number if variant
      
      '/' + base.compact.join('/')
    end
    
    def suite
      return @page.permalink if @page
      @page = Spree::Suite.joins(tabs: [:product]).merge(Spree::Product.where(slug: product.slug)).first
      @page ||= find_suite_by_product_name_and_type
      @page ||= find_suite_by_product_name
      @page.permalink if @page
    end

    def find_suite_by_product_name_and_type
      products = Spree::Product.where(name: product.name, product_type_id: product.product_type_id).joins(:suite_tabs)
      if products.any?
        products.first.suite_tabs.first.try(:suite)
      end
    end

    def find_suite_by_product_name
      products = Spree::Product.where(name: product.name).joins(:suite_tabs)
      if products.any?
        products.first.suite_tabs.first.try(:suite)
      end
    end

    
    def tab(product)
      return 'knit-your-own' if product.product_type.kit?
      'made-by-the-gang'
    end
    
  end
end
