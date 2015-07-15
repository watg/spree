module Spree
  class PinterestService < ActiveInteraction::Base
    # product page api
    # http://127.0.0.1:3000/api/pinterest/?url=http://127.0.0.1:3000/shop/items/zion-lion-men/made-by-the-gang/879
    # suite api
    # http://127.0.0.1:3000/api/pinterest/?url=http://127.0.0.1:3000/product/zion-lion-men/made-by-the-gang/879

    string :url

    attr_reader :suite, :tab, :variant

    def execute
      open_struct_result = nil

      if url.match(/product\/(.*)/)
        url_parts = $1.split("/")
        open_struct_result = suite_api( *url_parts )
      elsif url.match(/items\/(.*)/)
        url_parts = $1.split("/")
        open_struct_result = suite_api( *url_parts )
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

      load_suite(suite_permalink)
      return unless suite

      load_suite_tab(suite, suite_tab_type)

      product = tab.product
      return unless product

      load_variant(product, variant_number)

      OpenStruct.new({
        provider_name: "Wool and the Gang",
        url: variant_url(suite, tab, variant),
        title: fancy_title(product.name, tab.tab_type),
        description: product.clean_description_for(suite.target),
        product_id: variant.number,
        price: variant.current_price_in("GBP").amount,
        currency_code: "GBP",
        availability: variant.in_stock_cache ? "in stock" : "out of stock",
        gender: gender(suite.target),
        images: images(variant)
      })
    end


  private


    def gender(target)
      return 'unisex' unless target
      target.name.downcase
    end

    def load_suite(permalink)
      @suite = Suite.find_by(permalink: permalink)
    end

    def load_suite_tab(suite, tab_type=nil)
      @tab = suite.tabs.find {|tab| tab.tab_type == tab_type } ||
             suite.tabs.first
    end

    def load_variant(product, variant_number=nil)
      @variant = product.variants_including_master.find {|variant| variant.number == variant_number } ||
                 product.variants.first || product.variants_including_master.first
    end

    def images(variant)
      variant.images.first(6).map(&:attachment).map(&:url)
    end

    def fancy_title(product_name, suite_tab_type)
      case suite_tab_type
      when 'knit-your-own'
        product_name + " Knit Kit"
      when 'made-by-the-gang'
        product_name + ' #madeunique by The Gang'
      else
        product_name
      end
    end

    def variant_url(suite, tab, variant)
      Spree::Core::Engine.routes.url_helpers.suite_url(suite, tab.tab_type, variant.try(:number))
    end

  end
end
