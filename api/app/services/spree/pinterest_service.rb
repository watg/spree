module Spree
  class PinterestService <  ActiveInteraction::Base
    # product page api
    # http://0.0.0.0:3000/api/pinterest/?url=http://0.0.0.0:3000/shop/items/zion-lion-men/made-by-the-gang/879
    # suite api
    # http://0.0.0.0:3000/api/pinterest/?url=http://0.0.0.0:3000/product/zion-lion-men/made-by-the-gang/879

    string :url

    attr_reader :suite

    def execute
      open_struct_result = nil

      if url.match(/product\/(.*)/)
        url_parts = $1.split("/")
        open_struct_result = suite_api( *url_parts )
      elsif url.match(/items\/(.*)/)
        url_parts = $1.split("/")
        # new_api is in fact the old one, in time where we had index and product pages
        open_struct_result = new_api( *url_parts )
      else
        errors.add(:url, "Could not parse url")
      end

      if errors.empty? && !open_struct_result.kind_of?(OpenStruct)
        errors.add(:url, "Could not find requested product")
        return
      end

      open_struct_result
    end


    def suite_api(suite_permalink=nil, suite_tab_type=nil, variant_number=nil)

      suite = load_suite(suite_permalink)
      return unless suite

      suite_tab = load_suite_tab(suite, suite_tab_type)

      product = suite_tab.product
      return unless product

      variant = load_variant(product, variant_number)

      OpenStruct.new({
        provider_name: "Wool and the Gang",
        url: url,
        title: fancy_title(product.name, suite_tab_type),
        description: product.clean_description_for(suite.target),
        product_id: variant.number,
        price: variant.current_price_in("GBP").amount,
        currency_code: "GBP",
        availability: variant.in_stock_cache ? "in stock" : "out of stock",
        gender: gender(suite.target),
        images: images(variant)
      })
    end

    # new_api is in fact the old one, in time where we had index and product pages
    def new_api(product_page_slug, product_page_tab=nil, variant_id=nil)
      product_page = load_product_page(product_page_slug) if product_page_slug
      if !product_page
        errors.add(:url, "Could not find product page")
        return
      end

      product_page_tab ||=  Spree::ProductPageTab::MADE_BY_THE_GANG
      product_page_tab.gsub!('-','_')

      variant = nil
      variant = find_variant(variant_id, product_page_tab, product_page)

      if !variant
        errors.add(:url, "Could not find product page")
        return
      end

      product = variant.product.decorate

      OpenStruct.new({
        provider_name: "Wool and the Gang",
        url: url,
        title: fancy_title(product.name, product_page_tab),
        description: product.clean_description_for(product_page.target),
        product_id: variant.number,
        price: variant.current_price_in("GBP").amount,
        currency_code: "GBP",
        availability: variant.in_stock_cache ? "in stock" : "out of stock",
        gender: gender(product_page.target),
        images: images(variant)
      })

    end

  private

    def find_variant(variant_id, product_page_tab, product_page)
      variant = nil
      if variant_id
        variant = Spree::Variant.where(number: variant_id).first
      else

        if tabs = product_page.tabs.where(tab_type: product_page_tab)
          if products = tabs.map(&:product).flatten.compact
            if variants = products.map(&:variants).flatten.compact
              variant = variants.first
            end
          end
        end
        variant ||= product_page.variants.first

      end
      variant
    end


    def gender(target)
      return 'unisex' unless target
      target.name.downcase
    end

    def load_product_page(permalink)
      ProductPage.where(permalink: permalink).first
    end

    def load_suite(permalink)
      Suite.find_by(permalink: permalink)
    end

    def load_suite_tab(suite, tab_type=nil)
      suite.tabs.find {|tab| tab.tab_type == tab_type } ||
      suite.tabs.first
    end

    def load_variant(product, variant_number=nil)
      product.variants_including_master.find {|variant| variant.number == variant_number } ||
      product.variants.first || product.variants_including_master.first
    end

    def images(variant)
      variant.images.first(6).map(&:attachment).map(&:url)
    end

    def fancy_title(product_name, product_page_tab)
      case product_page_tab.gsub('-','_')
      when Spree::ProductPageTab::KNIT_YOUR_OWN
        product_name + " Knit Kit"
      when Spree::ProductPageTab::MADE_BY_THE_GANG
        product_name + ' #madeunique by The Gang'
      else
        product_name
      end
    end

  end
end
