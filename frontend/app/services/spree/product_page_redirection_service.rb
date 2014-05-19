module Spree
  class ProductPageRedirectionService < Mutations::Command
    optional do
      duck :product
      duck :variant
    end

    def execute
      {
        url:       product_pages_url,
        http_code: code,
        flash:     message
      }
    end
    
    private
    def code
      ((product.blank? || product_page.blank?) ? 302 : 301)
    end

    def message
      return "Item not found" if product.blank?
      return "Page not found" if product_page.blank?
    end

    def product_pages_url
      return '/' if product.blank?
      return '/' if product_page.blank?

      base = [
              'shop',
              'items',
              product_page,
              tab(product)]
      
      base << variant.number if variant
      
      '/' + base.compact.join('/')
    end
    
    def product_page
      return @page.permalink if @page
      taxonomies = product.taxons.group_by(&:taxonomy).keys.map {|e| e.name.downcase }
      
      target = (taxonomies.include?('women') ? Spree::Target.find_by_name('Women') : nil)
      target ||= (taxonomies.include?('men') ? Spree::Target.find_by_name('Men')   : nil)

      @page = product.product_group.product_pages.where(target_id: (target ? target.id : nil)).first
      @page.permalink if @page
    end
    
    def tab(product)
      return 'knit-your-own' if product.product_type.kit?
      'made-by-the-gang'
    end
    
  end
end
